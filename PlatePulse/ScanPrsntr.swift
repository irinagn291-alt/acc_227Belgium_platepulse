import AVFoundation
import UIKit

enum PermKind: Sendable {
    case ok
    case ask
    case denied
    case lock
    case none
}

struct ScanVM: Sendable {
    var perm: PermKind
    var permTitle: String
    var permBody: String
    var status: String
    var chips: [String]
    var hi: Bool
    var hasCam: Bool
}

@MainActor
protocol ScanView: AnyObject {
    func render(_ vm: ScanVM)
}

/// Live scan presenter. Large trigger confirms the last spoken code.
@MainActor
final class ScanPrsntr {
    weak var view: ScanView?
    weak var coord: FlowCoord?
    private let store: PulseMgr
    private let food: FoodSvc
    private var last = ""
    private var busy = false

    init(store: PulseMgr, food: FoodSvc) {
        self.store = store
        self.food = food
    }

    func reload() {
        Task { await push() }
    }

    func appear() {
        Task { await push() }
    }

    func heard(_ raw: String) {
        last = raw
        let spoken = CodeNorm.primary(raw) ?? raw
        UIAccessibility.post(notification: .announcement, argument: "Reading \(spoken)")
        Task { await push(status: "Heard \(spoken). Lock the reading to open detail.") }
    }

    func lock() {
        let raw = last.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty {
            Task { await push(status: "No code yet. Point at a barcode or type one.") }
            return
        }
        resolve(raw)
    }

    func typed(_ raw: String) {
        resolve(raw)
    }

    func chip(_ code: String) {
        resolve(code)
    }

    func askCam() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            Task { @MainActor in
                self?.reload()
            }
        }
    }

    private func resolve(_ raw: String) {
        guard !busy else { return }
        busy = true
        Task { [weak self] in
            guard let self else { return }
            if let cached = await cachedHit(raw) {
                busy = false
                coord?.picked(cached)
                return
            }
            do {
                let item = try await food.product(raw)
                await store.putFood(item)
                busy = false
                coord?.picked(item)
            } catch let e as FoodErr {
                busy = false
                switch e {
                case .notFound:
                    await push(status: "That barcode is not in Open Food Facts. Type a name on Search.")
                case .net:
                    await push(status: "No network for an uncached code. Try a shelf chip or wait for a signal.")
                case .decode:
                    await push(status: "The product reply was unreadable. Try again.")
                }
            } catch {
                busy = false
                await push(status: "The product reply failed. Try again.")
            }
        }
    }

    private func cachedHit(_ raw: String) async -> FoodItem? {
        for c in CodeNorm.cands(raw) {
            if let hit = await store.cached(c) { return hit }
            if let shelf = ShelfStore.byCode(c) { return shelf }
        }
        return nil
    }

    private func push(status: String? = nil) async {
        let hi = await store.prefs().hiContrast
        let has = AVCaptureDevice.default(for: .video) != nil
        let auth = AVCaptureDevice.authorizationStatus(for: .video)
        let perm: PermKind
        if !has {
            perm = .none
        } else {
            switch auth {
            case .authorized: perm = .ok
            case .notDetermined: perm = .ask
            case .denied: perm = .denied
            case .restricted: perm = .lock
            @unknown default: perm = .denied
            }
        }
        let title: String
        let body: String
        switch perm {
        case .ok:
            title = ""
            body = ""
        case .ask:
            title = "Camera is ready to listen"
            body = "Allow the camera so a barcode can become a reading."
        case .denied:
            title = "Camera is off"
            body = "Open Settings to let PlatePulse read barcodes."
        case .lock:
            title = "Camera is restricted"
            body = "Parental or device limits blocked the camera. Open Settings if you can change them."
        case .none:
            title = "No camera on this device"
            body = "Use a sample chip or type a barcode. The log still works."
        }
        view?.render(ScanVM(
            perm: perm,
            permTitle: title,
            permBody: body,
            status: status ?? "Live read. Each code is spoken, then lock it.",
            chips: ShelfStore.all.map(\.code),
            hi: hi,
            hasCam: has && perm == .ok
        ))
    }
}
