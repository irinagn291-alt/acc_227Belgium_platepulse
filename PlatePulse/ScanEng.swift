import AVFoundation
import UIKit

/// Session box. Touched only on `q`, so the capture engine stays race-free.
final class ScanBox: @unchecked Sendable {
    let sess = AVCaptureSession()
    let q = DispatchQueue(label: "plp.scan")
}

/// Live AVCaptureMetadataOutput engine. 19AUG pattern: EAN/UPC/QR/Code128, session queue, stop without tearing down auth.
@MainActor
final class ScanEng: NSObject {
    private let box = ScanBox()
    private var sess: AVCaptureSession { box.sess }
    private var q: DispatchQueue { box.q }
    private var preview: AVCaptureVideoPreviewLayer?
    private var didCfg = false
    private var lastVal: String?
    private var lastAt = Date.distantPast
    var onRead: ((String) -> Void)?

    var hasDevice: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func attach(to view: UIView) {
        if let preview {
            preview.frame = view.bounds
            if preview.superlayer !== view.layer {
                preview.removeFromSuperlayer()
                view.layer.insertSublayer(preview, at: 0)
            }
            return
        }
        let layer = AVCaptureVideoPreviewLayer(session: sess)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
    }

    func layout(in view: UIView) {
        preview?.frame = view.bounds
    }

    func start() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        boot()
    }

    func stop() {
        let box = self.box
        box.q.async {
            if box.sess.isRunning { box.sess.stopRunning() }
        }
    }

    func handle(_ raw: String) {
        let now = Date()
        if raw == lastVal, now.timeIntervalSince(lastAt) < 1.8 { return }
        if now.timeIntervalSince(lastAt) < 1.8 { return }
        lastVal = raw
        lastAt = now
        onRead?(raw)
    }

    private func boot() {
        cfgIfNeeded()
        let box = self.box
        box.q.async {
            if !box.sess.isRunning { box.sess.startRunning() }
        }
    }

    private func cfgIfNeeded() {
        guard !didCfg else { return }
        didCfg = true
        sess.beginConfiguration()
        sess.sessionPreset = .high
        guard let cam = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: cam),
              sess.canAddInput(input) else {
            sess.commitConfiguration()
            return
        }
        sess.addInput(input)
        let out = AVCaptureMetadataOutput()
        guard sess.canAddOutput(out) else {
            sess.commitConfiguration()
            return
        }
        sess.addOutput(out)
        out.setMetadataObjectsDelegate(self, queue: q)
        let wanted: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128, .qr]
        out.metadataObjectTypes = wanted.filter { out.availableMetadataObjectTypes.contains($0) }
        sess.commitConfiguration()
    }
}

extension ScanEng: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput objects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let val = obj.stringValue else { return }
        Task { @MainActor in
            self.handle(val)
        }
    }
}
