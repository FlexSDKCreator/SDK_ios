//
//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation
import CoreVideo
//import MLImage
//import MLKit
import MLKitBarcodeScanning
import MLKitVision

@objc(CameraViewController)
class CameraViewController: UIViewController {
    private let detectors: [Detector] = [
        .onDeviceBarcode,
    ]
    
    private var currentDetector: Detector = .onDeviceBarcode
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    private var lastFrame: CMSampleBuffer?
    var isUsingFrontCamera = false
    var isMulti: Bool = false
    var height: CGFloat = 0
    var width: CGFloat = 0
    var isHeightPercent: Bool = false
    var isWidthPercent: Bool = false
    var closeBtnOnVideo: Bool = false
    var isQR: Bool = false
    var closeBtnConstrains: [NSLayoutConstraint]?
    var cameraViewConstraints: [NSLayoutConstraint]?
    var onScannerResult: ((Bool, String?, String?) -> Void)?
    
    private lazy var annotationOverlayView: UIView = {
        precondition(isViewLoaded)
        let annotationOverlayView = UIView(frame: .zero)
        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return annotationOverlayView
    }()
    
    /// The detector mode with which detection was most recently run. Only used on the video output
    /// queue. Useful for inferring when to reset detector instances which use a conventional
    /// lifecyle paradigm.
    private var lastDetector: Detector?
    
    // MARK: - IBOutlets
    //@IBOutlet private weak var cameraView: UIView!
    private var cameraView = UIView()
    private var closeBtn = UIButton();
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cameraView)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)//UIColor.clear
        view.isOpaque = false
        closeBtn.setImage(UIImage(named: "close_btn_34"), for: .normal)
        closeBtn.imageView?.contentMode = .scaleAspectFit
        closeBtn.addTarget(self, action: #selector(closeBtnClick), for: UIControl.Event.touchUpInside)
        view.addSubview(closeBtn)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.clipsToBounds = true
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.clipsToBounds = true
        let constraints = [
            cameraView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor),
            cameraView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            cameraView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cameraView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeBtn.widthAnchor.constraint(equalToConstant: 34),
            closeBtn.heightAnchor.constraint(equalToConstant: 34)
        ]
        NSLayoutConstraint.activate(constraints)
        applyMeasuredDimentions()
        
        /*let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissViewController))
         tapGestureRecognizer.cancelsTouchesInView = false
         view.addGestureRecognizer(tapGestureRecognizer)*/
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.insertSublayer(previewLayer, at: 0)
        
        setUpAnnotationOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGesture(_:)))
        self.view.addGestureRecognizer(panGesture)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.applyMeasuredDimentions()
        })
    }
    fileprivate func applyMeasuredDimentions() {
        let viewHeight = view.frame.height
        let viewWeight = view.frame.width
        var heightMeasure = height
        var widthMeasure = width
        if (height > 0) {
            if (isHeightPercent) {
                heightMeasure = viewHeight * min (100, height) / 100
            }
        } else {
            heightMeasure = viewHeight
        }
        if (width > 0) {
            if (isWidthPercent) {
                widthMeasure = viewWeight * min (100, width) / 100
            }
        } else {
            widthMeasure = viewWeight
        }
        if (isQR) {
            heightMeasure = min (heightMeasure, widthMeasure)
            widthMeasure = heightMeasure
        }
        if let camCons = cameraViewConstraints {
            NSLayoutConstraint.deactivate(camCons)
        }
        cameraViewConstraints = []
        let heightCons = cameraView.heightAnchor.constraint(equalToConstant: heightMeasure)
        heightCons.priority = .defaultLow
        cameraViewConstraints?.append(heightCons)
        let widthCons = cameraView.widthAnchor.constraint(equalToConstant: widthMeasure)
        widthCons.priority = .defaultLow
        cameraViewConstraints?.append(widthCons)
        if let camCons = cameraViewConstraints {
            NSLayoutConstraint.activate(camCons)
        }
        if let camCons = closeBtnConstrains {
            NSLayoutConstraint.deactivate(camCons)
        }
        closeBtnConstrains = []
        if (closeBtnOnVideo) {
            closeBtnConstrains?.append(closeBtn.bottomAnchor.constraint(equalTo: cameraView.topAnchor, constant: -10))
            closeBtnConstrains?.append(closeBtn.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -10))
        } else {
            closeBtnConstrains?.append(closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10))
            closeBtnConstrains?.append(closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10))
        }
        if let closeCons = closeBtnConstrains {
            NSLayoutConstraint.activate(closeCons)
        }
    }
    @objc func handleDismissGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        // Check for downward gesture
        if translation.y > 0 {
            switch gesture.state {
            case .changed:
                self.view.frame.origin.y = translation.y
            case .ended:
                if translation.y > 100 { // You can adjust this threshold
                    closeBtnClick(tap: nil)
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.view.frame.origin.y = 0
                    }
                }
            default:
                break
            }
        }
    }
    @objc func closeBtnClick(tap: UITapGestureRecognizer?) {
        onScannerResult?(false, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    @objc func dismissViewController(tap: UITapGestureRecognizer) {
        let location = tap.location(in: view)
        let imageSize = cameraView.intrinsicContentSize // The size of the content (the image)
        // Calculate the rect of the actual image within the imageView
        let imageViewSize = cameraView.bounds.size
        var imageFrame = CGRect.zero
        let aspectFitSize = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: imageViewSize))
        imageFrame.size = aspectFitSize.size
        imageFrame.origin.x = (imageViewSize.width - aspectFitSize.width) / 2.0
        imageFrame.origin.y = (imageViewSize.height - aspectFitSize.height) / 2.0
        
        // Check if the tap is inside the image frame
        if !imageFrame.contains(location) {
            onScannerResult?(false, nil, nil)
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
        if closeBtnOnVideo && closeBtn.frame.minY < 0 {
            if let camCons = closeBtnConstrains {
                NSLayoutConstraint.deactivate(camCons)
            }
            closeBtnConstrains?.append(closeBtn.topAnchor.constraint(equalTo: cameraView.topAnchor, constant: 10))
            closeBtnConstrains?.append(closeBtn.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -10))
            if let closeCons = closeBtnConstrains {
                NSLayoutConstraint.activate(closeCons)
            }
        }
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
        }
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .landscapeRight:
            return .landscapeLeft // because the camera sees mirrored
        case .landscapeLeft:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func selectDetector(_ sender: Any) {
        presentDetectorsAlertController()
    }
    
    @IBAction func switchCamera(_ sender: Any) {
        isUsingFrontCamera = !isUsingFrontCamera
        removeDetectionAnnotations()
        setUpCaptureSessionInput()
    }
    
    // MARK: On-Device Detections
    
    fileprivate func showBarcode(_ barcode: Barcode, _ strongSelf: CameraViewController, _ width: CGFloat, _ height: CGFloat, _ orientation: UIImage.Orientation) {
        let normalizedRect = CGRect(
            x: barcode.frame.origin.x / width,
            y: barcode.frame.origin.y / height,
            width: barcode.frame.size.width / width,
            height: barcode.frame.size.height / height
        )
        let convertedRect = strongSelf.previewLayer.layerRectConverted(
            fromMetadataOutputRect: normalizedRect
        )
        UIUtilities.addRectangle(
            convertedRect,
            to: strongSelf.annotationOverlayView,
            color: UIColor.green
        )
        let label = UILabel(frame: convertedRect)
        label.text = barcode.displayValue
        label.adjustsFontSizeToFitWidth = true
        strongSelf.rotate(label, orientation: orientation)
        strongSelf.annotationOverlayView.addSubview(label)
    }
    
    private func scanBarcodesOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
        // Define the options for a barcode detector.
        let format = BarcodeFormat.all
        let barcodeOptions = BarcodeScannerOptions(formats: format)
        
        // Create a barcode scanner.
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        var barcodes: [Barcode] = []
        var scanningError: Error?
        do {
            barcodes = try barcodeScanner.results(in: image)
        } catch let error {
            scanningError = error
        }
        weak var weakSelf = self
        DispatchQueue.main.sync {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            
            if let scanningError = scanningError {
                print("Failed to scan barcodes with error: \(scanningError.localizedDescription).")
                return
            }
            guard !barcodes.isEmpty else {
                print("Barcode scanner returrned no results.")
                return
            }
            if barcodes.count > 0 {
                
                var result : String = "";
                var hasResult : Bool = false;
                var barcode : Barcode
                
                var listOfCodes = [String]()
                for i in 0..<barcodes.count {
                    barcode = barcodes[i]
                    let normalizedRect = CGRect(
                        x: barcode.frame.origin.x / width,
                        y: barcode.frame.origin.y / height,
                        width: barcode.frame.size.width / width,
                        height: barcode.frame.size.height / height
                    )
                    let convertedRect = strongSelf.previewLayer.layerRectConverted(
                        fromMetadataOutputRect: normalizedRect
                    )
                    if cameraView.bounds.contains(convertedRect) {
                        captureSession.stopRunning()
                        hasResult = true
                        showBarcode(barcode, strongSelf, width, height, image.orientation)
                        listOfCodes.append(barcode.rawValue ?? (barcode.displayValue ?? ""))
                        if !isMulti {
                            result = barcode.rawValue ?? (barcode.displayValue ?? "")
                            break
                        }
                    }
                }
                do {
                    if (hasResult && isMulti) {
                        let jsonData = try JSONSerialization.data(withJSONObject: listOfCodes, options: [])
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result = jsonString
                        }
                    }
                } catch {
                    onScannerResult?(false, nil, error.localizedDescription)
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                if (hasResult) {
                    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
                    onScannerResult?(true, result, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        // Put your dismiss code here
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Private
    
    private func setUpCaptureSessionOutput() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
            output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
            guard strongSelf.captureSession.canAddOutput(output) else {
                print("Failed to add capture session output.")
                return
            }
            strongSelf.captureSession.addOutput(output)
            strongSelf.captureSession.commitConfiguration()
        }
    }
    
    private func setUpCaptureSessionInput() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
            guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            do {
                strongSelf.captureSession.beginConfiguration()
                let currentInputs = strongSelf.captureSession.inputs
                for input in currentInputs {
                    strongSelf.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard strongSelf.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                strongSelf.captureSession.addInput(input)
                strongSelf.captureSession.commitConfiguration()
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    private func startSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.startRunning()
            if let connection = self.previewLayer.connection {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = self.currentVideoOrientation()
                }
            }
        }
    }
    
    private func stopSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.stopRunning()
        }
    }
    
    private func setUpAnnotationOverlayView() {
        cameraView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
            annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
        ])
    }
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {   
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )
            return discoverySession.devices.first { $0.position == position }
        }
        return nil
    }
    
    private func presentDetectorsAlertController() {
        let alertController = UIAlertController(
            title: Constant.alertControllerTitle,
            message: Constant.alertControllerMessage,
            preferredStyle: .alert
        )
        weak var weakSelf = self
        detectors.forEach { detectorType in
            let action = UIAlertAction(title: detectorType.rawValue, style: .default) {
                [unowned self] (action) in
                guard let value = action.title else { return }
                guard let detector = Detector(rawValue: value) else { return }
                guard let strongSelf = weakSelf else {
                    print("Self is nil!")
                    return
                }
                strongSelf.currentDetector = detector
                strongSelf.removeDetectionAnnotations()
            }
            if detectorType.rawValue == self.currentDetector.rawValue { action.isEnabled = false }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: Constant.cancelActionTitleText, style: .cancel))
        present(alertController, animated: true)
    }
    
    private func removeDetectionAnnotations() {
        for annotationView in annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    private func convertedPoints(
        from points: [NSValue]?,
        width: CGFloat,
        height: CGFloat
    ) -> [NSValue]? {
        return points?.map {
            let cgPointValue = $0.cgPointValue
            let normalizedPoint = CGPoint(x: cgPointValue.x / width, y: cgPointValue.y / height)
            let cgPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
            let value = NSValue(cgPoint: cgPoint)
            return value
        }
    }
    
    private func normalizedPoint(
        fromVisionPoint point: VisionPoint,
        width: CGFloat,
        height: CGFloat
    ) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        return normalizedPoint
    }
    
    
    /// Resets any detector instances which use a conventional lifecycle paradigm. This method is
    /// expected to be invoked on the AVCaptureOutput queue - the same queue on which detection is
    /// run.
    private func resetManagedLifecycleDetectors(activeDetector: Detector) {
        if activeDetector == self.lastDetector {
            // Same row as before, no need to reset any detectors.
            return
        }
        self.lastDetector = activeDetector
    }
    
    private func rotate(_ view: UIView, orientation: UIImage.Orientation) {
        var degree: CGFloat = 0.0
        switch orientation {
        case .up, .upMirrored:
            degree = 90.0
        case .rightMirrored, .left:
            degree = 180.0
        case .down, .downMirrored:
            degree = 270.0
        case .leftMirrored, .right:
            degree = 0.0
        @unknown default:
            degree = 0.0
        }
        view.transform = CGAffineTransform.init(rotationAngle: degree * 3.141592654 / 180)
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        // Evaluate `self.currentDetector` once to ensure consistency throughout this method since it
        // can be concurrently modified from the main thread.
        let activeDetector = self.currentDetector
        resetManagedLifecycleDetectors(activeDetector: activeDetector)
        
        lastFrame = sampleBuffer
        let visionImage = VisionImage(buffer: sampleBuffer)
        let orientation = UIUtilities.imageOrientation(
            fromDevicePosition: isUsingFrontCamera ? .front : .back
        )
        visionImage.orientation = orientation
        
//        guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
//            print("Failed to create MLImage from sample buffer.")
//            return
//        }
//        inputImage.orientation = orientation
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        scanBarcodesOnDevice(in: visionImage, width: imageWidth, height: imageHeight)
    }
}

// MARK: - Constants

public enum Detector: String {
    case onDeviceBarcode = "Barcode Scanning"
}

private enum Constant {
    static let alertControllerTitle = "Vision Detectors"
    static let alertControllerMessage = "Select a detector"
    static let cancelActionTitleText = "Cancel"
    static let videoDataOutputQueueLabel = "com.google.mlkit.visiondetector.VideoDataOutputQueue"
    static let sessionQueueLabel = "com.google.mlkit.visiondetector.SessionQueue"
    static let noResultsMessage = "No Results"
    static let localModelFile = (name: "bird", type: "tflite")
    static let labelConfidenceThreshold = 0.75
    static let smallDotRadius: CGFloat = 4.0
    static let lineWidth: CGFloat = 3.0
    static let originalScale: CGFloat = 1.0
    static let padding: CGFloat = 10.0
    static let resultsLabelHeight: CGFloat = 200.0
    static let resultsLabelLines = 5
    static let imageLabelResultFrameX = 0.4
    static let imageLabelResultFrameY = 0.1
    static let imageLabelResultFrameWidth = 0.5
    static let imageLabelResultFrameHeight = 0.8
    static let segmentationMaskAlpha: CGFloat = 0.5
}

protocol CodeScannerDelegate {
    func onScannerResult(success: Bool, code: String?, message: String?)
}
