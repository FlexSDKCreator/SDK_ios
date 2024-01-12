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
import MLKit

@objc(CameraViewController)
class CameraViewController: UIViewController {
    private let detectors: [Detector] = [
        .onDeviceBarcode,
    ]
    
    private var currentDetector: Detector = .onDeviceBarcode
    private var isUsingFrontCamera = false
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    private var lastFrame: CMSampleBuffer?
    var isMulti: Bool = false
    var onScannerResult: ((Bool, String?, String?) -> Void)?
    
    private lazy var previewOverlayView: UIImageView = {
        
        precondition(isViewLoaded)
        let previewOverlayView = UIImageView(frame: .zero)
        previewOverlayView.contentMode = UIView.ContentMode.scaleAspectFit
        previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return previewOverlayView
    }()
    
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
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cameraView)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)//UIColor.clear
        view.isOpaque = false
        let closeBtn = UIButton();
        closeBtn.setImage(UIImage(named: "close_btn_34"), for: .normal)
        closeBtn.imageView?.contentMode = .scaleAspectFit
        closeBtn.addTarget(self, action: #selector(closeBtnClick), for: UIControl.Event.touchUpInside)
        view.addSubview(closeBtn)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            closeBtn.widthAnchor.constraint(equalToConstant: 34),
            closeBtn.heightAnchor.constraint(equalToConstant: 34)
        ])
        /*let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissViewController))
         tapGestureRecognizer.cancelsTouchesInView = false
         view.addGestureRecognizer(tapGestureRecognizer)*/
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspect
        setUpPreviewOverlayView()
        setUpAnnotationOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGesture(_:)))
        self.view.addGestureRecognizer(panGesture)
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
        
        let imageSize = previewOverlayView.intrinsicContentSize // The size of the content (the image)
        
        // Calculate the rect of the actual image within the imageView
        let imageViewSize = previewOverlayView.bounds.size
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
            strongSelf.updatePreviewOverlayViewWithLastFrame()
            
            if let scanningError = scanningError {
                print("Failed to scan barcodes with error: \(scanningError.localizedDescription).")
                return
            }
            guard !barcodes.isEmpty else {
                print("Barcode scanner returrned no results.")
                return
            }
            if barcodes.count > 0 {
                captureSession.stopRunning()
                var result : String = "";
                var barcode : Barcode
                if isMulti {
                    var listOfCodes = [String]()
                    for i in 0..<barcodes.count {
                        barcode = barcodes[i]
                        showBarcode(barcode, strongSelf, width, height, image.orientation)
                        listOfCodes.append(barcode.rawValue ?? (barcode.displayValue ?? ""))
                    }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: listOfCodes, options: [])
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            result = jsonString
                        }
                    } catch {
                        onScannerResult?(false, nil, error.localizedDescription)
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                } else {
                    barcode = barcodes[0]
                    result = barcode.rawValue ?? (barcode.displayValue ?? "")
                    showBarcode(barcode, strongSelf, width, height, image.orientation)
                }
                
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
                onScannerResult?(true, result, nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    // Put your dismiss code here
                    self.dismiss(animated: true, completion: nil)
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
            strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            
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
    
    private func setUpPreviewOverlayView() {
        cameraView.addSubview(previewOverlayView)
        //    NSLayoutConstraint.activate([
        //      previewOverlayView.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
        //      previewOverlayView.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
        //      previewOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
        //      previewOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
        //
        //    ])
        NSLayoutConstraint.activate([
            previewOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            previewOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            previewOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            previewOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            
        ])
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
    
    private func updatePreviewOverlayViewWithLastFrame() {
        guard let lastFrame = lastFrame,
              let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
        else {
            return
        }
        self.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
        self.removeDetectionAnnotations()
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
        guard let imageBuffer = imageBuffer else {
            return
        }
        let orientation: UIImage.Orientation = isUsingFrontCamera ? .leftMirrored : .right
        let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
        previewOverlayView.image = image
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
        
        guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
            print("Failed to create MLImage from sample buffer.")
            return
        }
        inputImage.orientation = orientation
        
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
