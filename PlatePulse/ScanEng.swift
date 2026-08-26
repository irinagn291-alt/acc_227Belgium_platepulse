import AVFoundation
import UIKit

/// Session box. Touched only on `q`, so the capture engine stays race-free.
final class ScanBox: @unchecked Sendable {
    let sess = AVCaptureSession()
    let q = DispatchQueue(label: "plp.scan")
}

/// Live AVCaptureMetadataOutput engine with debounce and a large trigger.
@MainActor
final class ScanEng: NSObject {
    private let box = ScanBox()
    private var sess: AVCaptureSession { box.sess }
    private var q: DispatchQueue { box.q }
    private var preview: AVCaptureVideoPreviewLayer?
    private var lastVal: String?
    private var lastAt = Date.distantPast
    var onRead: ((String) -> Void)?

    var hasDevice: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func attach(to view: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: sess)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.sublayers?.filter { $0 is AVCaptureVideoPreviewLayer }.forEach { $0.removeFromSuperlayer() }
        view.layer.insertSublayer(layer, at: 0)
        preview = layer
    }

    func layout(in view: UIView) {
        preview?.frame = view.bounds
    }

    func prep() {
        guard hasDevice, sess.inputs.isEmpty else { return }
        guard let cam = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: cam) else { return }
        if sess.canAddInput(input) { sess.addInput(input) }
        let out = AVCaptureMetadataOutput()
        if sess.canAddOutput(out) {
            sess.addOutput(out)
            out.setMetadataObjectsDelegate(self, queue: q)
            let all: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .qr, .code128]
            out.metadataObjectTypes = all.filter { out.availableMetadataObjectTypes.contains($0) }
        }
        sess.sessionPreset = .high
    }

    func start() {
        let box = self.box
        box.q.async {
            if !box.sess.isRunning { box.sess.startRunning() }
        }
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
