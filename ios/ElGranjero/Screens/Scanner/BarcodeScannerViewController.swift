import UIKit
import AVFoundation
import AudioToolbox

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let onScan: (String) -> Void
    private var didScan = false

    // Supported barcode types
    static let supportedTypes: [AVMetadataObject.ObjectType] = [
        .ean13, .ean8, .upce, .code128, .code39, .code39Mod43, .code93,
        .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix
    ]

    init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.stopRunning() }
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            showCameraError(); return
        }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = Self.supportedTypes
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }

    private func setupOverlay() {
        // Dimmed overlay with cutout
        let overlay = UIView(); overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor), overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor), overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Scan region cutout (using mask)
        let scanSize: CGFloat = min(view.bounds.width, view.bounds.height) * 0.65
        let scanRect = CGRect(x: (view.bounds.width - scanSize) / 2, y: (view.bounds.height - scanSize) / 2 - 50, width: scanSize, height: scanSize)
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: scanRect, cornerRadius: 16).reversing())
        let mask = CAShapeLayer(); mask.path = path.cgPath; overlay.layer.mask = mask

        // Corner brackets
        for (x, y) in [(scanRect.minX, scanRect.minY), (scanRect.maxX, scanRect.minY), (scanRect.minX, scanRect.maxY), (scanRect.maxX, scanRect.maxY)] {
            let bracket = UIView(); bracket.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1); bracket.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bracket)
            let h: CGFloat = 3; let w: CGFloat = 30
            bracket.frame = CGRect(x: x - h/2, y: y - w/2 + (y == scanRect.minY ? h : -h), width: (x == scanRect.minX ? w : -w), height: h)
            // Simpler: just 4 corner views instead of rotated lines
        }

        // Simpler corner indicators
        let corners: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (scanRect.minX - 16, scanRect.minY - 16, 40, 3), (scanRect.minX - 16, scanRect.minY - 16, 3, 40), // top-left
            (scanRect.maxX - 24, scanRect.minY - 16, 40, 3), (scanRect.maxX + 13, scanRect.minY - 16, 3, 40),   // top-right
            (scanRect.minX - 16, scanRect.maxY + 13, 40, 3), (scanRect.minX - 16, scanRect.maxY - 24, 3, 40),  // bottom-left
            (scanRect.maxX - 24, scanRect.maxY + 13, 40, 3), (scanRect.maxX + 13, scanRect.maxY - 24, 3, 40),  // bottom-right
        ]
        for (x, y, w, h) in corners {
            let v = UIView(); v.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1); v.frame = CGRect(x: x, y: y, width: w, height: h)
            v.layer.cornerRadius = 1.5; view.addSubview(v)
        }

        // Instructions label
        let label = UILabel(); label.text = "Apunte al código de barras"; label.textColor = .white; label.font = .systemFont(ofSize: 16, weight: .medium); label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: (view.bounds.height - scanSize) / 2 - 55),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // Cancel button
        let cancelBtn = UIButton(type: .system); cancelBtn.setTitle("Cancelar", for: .normal); cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 17); cancelBtn.addTarget(self, action: #selector(dismissScanner), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(cancelBtn)
        NSLayoutConstraint.activate([
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        ])

        // Flashlight toggle
        let flashBtn = UIButton(type: .system); flashBtn.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal); flashBtn.tintColor = .white
        flashBtn.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        flashBtn.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(flashBtn)
        NSLayoutConstraint.activate([
            flashBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            flashBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flashBtn.widthAnchor.constraint(equalToConstant: 44), flashBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan, let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = obj.stringValue else { return }
        didScan = true
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        dismiss(animated: true) { self.onScan(code) }
    }

    @objc private func dismissScanner() { dismiss(animated: true) }

    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }

    private func showCameraError() {
        let alert = UIAlertController(title: "Error", message: "No se pudo acceder a la cámara.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.dismissScanner() })
        present(alert, animated: true)
    }
}
