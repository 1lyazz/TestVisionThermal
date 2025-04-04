import AVFoundation
import CoreImage.CIFilterBuiltins
import UIKit

protocol CameraManagerProtocol: AnyObject, ObservableObject {
    var isRecording: Bool { get }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }

    func setupSession(completion: @escaping (Result<Void, CameraError>) -> Void)
    func capturePhoto(completion: @escaping (Result<UIImage, CameraError>) -> Void)
    func startRecording(completion: @escaping (Result<URL, CameraError>) -> Void)
    func stopRecording()
    func flipCamera()
    func focus(at point: CGPoint)
    func switchCameraType(to type: CameraType)
}

final class CameraSessionManager: NSObject, CameraManagerProtocol {
    @Published private(set) var isRecording = false
    @Published private(set) var currentFilter: CameraFilterType = .original {
        didSet {
            updatePreviewFilters()
        }
    }

    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var activeCamera: AVCaptureDevice?
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var captureHandlers = CaptureHandlers()
    
    // MARK: - Session Setup

    func setupSession(completion: @escaping (Result<Void, CameraError>) -> Void) {
        checkPermissions { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.sessionQueue.async {
                    do {
                        try self.configureSession()
                        DispatchQueue.main.async {
                            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                            completion(.success(()))
                        }
                        self.captureSession.startRunning()
                    } catch let error as CameraError {
                        completion(.failure(error))
                    } catch {
                        completion(.failure(.unknown))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func checkPermissions(completion: @escaping (Result<Void, CameraError>) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(.success(()))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                granted ? completion(.success(())) : completion(.failure(.permissionDenied))
            }
        default:
            completion(.failure(.permissionDenied))
        }
    }
    
    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
        else {
            throw CameraError.deviceSetupFailed
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            self.videoInput = videoInput
            activeCamera = videoDevice
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        do {
            try configureAudioInput()
        } catch {
            print("Audio configuration failed, continuing without audio: \(error)")
        }
    }
    
    private func configureAudioInput() throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            throw CameraError.deviceSetupFailed
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
            self.audioInput = audioInput
        }
    }
    
    // MARK: - Camera Controls

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let currentInput = self.videoInput,
                  let newDevice = self.getAlternateCamera() else { return }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                self.captureSession.beginConfiguration()
                self.captureSession.removeInput(currentInput)
                
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoInput = newInput
                    self.activeCamera = newDevice
                } else {
                    self.captureSession.addInput(currentInput)
                }
                
                self.captureSession.commitConfiguration()
            } catch {
                print("Camera flip failed: \(error)")
            }
        }
    }
    
    private func getAlternateCamera() -> AVCaptureDevice? {
        guard let currentCamera = videoInput?.device else { return nil }
        let newPosition: AVCaptureDevice.Position = currentCamera.position == .back ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
    }
    
    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.activeCamera else { return }
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
            } catch {
                print("Focus error: \(error)")
            }
        }
    }
    
    func setCurrentFilter(_ filter: CameraFilterType) {
        sessionQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.currentFilter = filter
            }
        }
    }
    
    private func updatePreviewFilters() {
        previewLayer?.filters = currentFilter.coreImageFilters
    }
    
    // MARK: - Camera Type Handling

    func switchCameraType(to type: CameraType) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }
            
            self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
            
            switch type {
            case .photoCamera:
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }
            case .videoCamera:
                self.configureVideoOutput()
            }
        }
    }
    
    private func configureVideoOutput() {
        guard captureSession.canAddOutput(movieOutput) else { return }
        captureSession.addOutput(movieOutput)
        
        if let connection = movieOutput.connection(with: .video),
           connection.isVideoStabilizationSupported
        {
            connection.preferredVideoStabilizationMode = .auto
        }
    }
    
    // MARK: - Capture Methods

    func capturePhoto(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let settings = AVCapturePhotoSettings()
            self.captureHandlers.photoCompletion = { result in
                switch result {
                case .success(let image):
                    let filteredImage = self.applyFilter(to: image)
                    completion(.success(filteredImage))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: photoOutput.availablePhotoPixelFormatTypes.first!,
            kCVPixelBufferWidthKey as String: 720,
            kCVPixelBufferHeightKey as String: 1280
        ]
    }
    
    func startRecording(completion: @escaping (Result<URL, CameraError>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            self.captureHandlers.videoCompletion = completion
            self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            DispatchQueue.main.async { self.isRecording = true }
        }
    }
    
    func stopRecording() {
        sessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()
            DispatchQueue.main.async { self?.isRecording = false }
        }
    }
    
    private func applyFilter(to image: UIImage) -> UIImage {
        guard currentFilter != .original,
              let ciImage = CIImage(image: image)
        else {
            return image
        }
        
        let context = CIContext(options: nil)
        var outputImage: CIImage = ciImage
        
        switch currentFilter {
        case .thermal:
            let gradientColors = [
                UIColor.blue.cgColor,
                UIColor.green.cgColor,
                UIColor.yellow.cgColor,
                UIColor.red.cgColor
            ]
            
            let gradientLocations: [CGFloat] = [0.0, 0.15, 0.25, 0.35, 1.0]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: gradientColors as CFArray,
                                      locations: gradientLocations)
            
            let gradientSize = CGSize(width: 256, height: 1)
            UIGraphicsBeginImageContext(gradientSize)
            let context = UIGraphicsGetCurrentContext()
            context?.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: gradientSize.width, y: 0),
                options: []
            )
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let gradientCIImage = CIImage(image: gradientImage!) else {
                return UIImage()
            }
            
            if let colorMap = CIFilter(name: "CIColorMap") {
                colorMap.setValue(ciImage, forKey: kCIInputImageKey)
                colorMap.setValue(gradientCIImage, forKey: "inputGradientImage")
                if let colorMap = colorMap.outputImage {
                    outputImage = colorMap
                }
            }
            
        case .night:
            if let contrastFilter = CIFilter(name: "CIColorControls") {
                contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
                contrastFilter.setValue(2.0, forKey: kCIInputContrastKey)
                if let contrasted = contrastFilter.outputImage {
                    outputImage = contrasted
                }
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.0, green: 1.0, blue: 0.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let mono = monoFilter.outputImage {
                    outputImage = mono
                }
            }
            
            if let noiseFilter = CIFilter(name: "CINoiseReduction") {
                noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
                noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
                noiseFilter.setValue(0.4, forKey: "inputSharpness")
                if let noiseReduced = noiseFilter.outputImage {
                    outputImage = noiseReduced
                }
            }
            
        case .glitch:
            if let filter = currentFilter.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
            
        case .neon:
            if let filter = currentFilter.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.8, green: 0.0, blue: 1.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let mono = monoFilter.outputImage {
                    outputImage = mono
                }
            }
            
        default:
            if let filter = currentFilter.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Capture Handlers

private struct CaptureHandlers {
    var photoCompletion: ((Result<UIImage, CameraError>) -> Void)?
    var videoCompletion: ((Result<URL, CameraError>) -> Void)?
}

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?)
    {
        if error != nil {
            captureHandlers.photoCompletion?(.failure(.captureFailed))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData)
        else {
            captureHandlers.photoCompletion?(.failure(.captureFailed))
            return
        }
        
        captureHandlers.photoCompletion?(.success(image))
    }
}

extension CameraSessionManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?)
    {
        if let error = error {
            captureHandlers.videoCompletion?(.failure(.fileOutputFailed))
            print("Recording error: \(error.localizedDescription)")
            return
        }
        
        captureHandlers.videoCompletion?(.success(outputFileURL))
    }
}

extension CameraFilterType {
    var coreImageFilter: CIFilter? {
        switch self {
        case .original:
            return nil
        case .thermal:
            return CIFilter()
        case .heat:
            return CIFilter(name: "CIThermal")
        case .night:
            return CIFilter()
        case .xRay:
            let xRayFilter = CIFilter.xRay()
            return xRayFilter
        case .glitch:
            let filter = CIFilter.hueAdjust()
            filter.angle = 5
            return filter
        case .halftone:
            return CIFilter(name: "CICMYKHalftone")
        case .invert:
            return CIFilter(name: "CIColorInvert")
        case .noir:
            return CIFilter(name: "CIPhotoEffectNoir")
        case .neon:
            return CIFilter(name: "CIColorInvert")
        case .chrome:
            return CIFilter(name: "CIPhotoEffectChrome")
        case .spotColor:
            return CIFilter(name: "CISpotColor")
        case .draw:
            return CIFilter(name: "CIEdgeWork")
        case .blur:
            return CIFilter(name: "CIDiscBlur")
        case .motionBlur:
            return CIFilter(name: "CIMotionBlur")
        case .pixel:
            return CIFilter(name: "CIPixellate")
        case .circlePixel:
            return CIFilter(name: "CIHexagonalPixellate")
        case .crystallizePixel:
            return CIFilter(name: "CICrystallize")
        }
    }
    
    var coreImageFilters: [CIFilter] {
        guard let filter = coreImageFilter else { return [] }
        return [filter]
    }
}
