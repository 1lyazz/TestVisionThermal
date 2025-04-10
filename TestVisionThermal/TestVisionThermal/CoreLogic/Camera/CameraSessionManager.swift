import AVFoundation
import UIKit

protocol CameraManagerProtocol: AnyObject, ObservableObject {
    var isRecording: Bool { get }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }

    func setupSession(completion: @escaping (Result<Void, CameraError>) -> Void)
    func capturePhoto(completion: @escaping (Result<(UIImage, URL), CameraError>) -> Void)
    func startRecording(completion: @escaping (Result<URL, CameraError>) -> Void)
    func stopRecording()
    func flipCamera()
    func focus(at point: CGPoint)
    func switchCameraType(to type: CameraType)
}

final class CameraSessionManager: NSObject, CameraManagerProtocol, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var currentFilter: CameraFilterType = .original {
        didSet {
            updatePreviewFilters()
        }
    }
    
    // MARK: - Capture Session
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // MARK: - Inputs & Outputs
    
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    
    private var activeCamera: AVCaptureDevice?
    private var audioWriterInput: AVAssetWriterInput?
    private var initialZoom: CGFloat = 1.0
    private var captureHandlers = CaptureHandlers()
    private let filterProcessor = ImageFilterProcessor()
    private var addToPreviewStream: ((CGImage) -> Void)?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    lazy var previewStream: AsyncStream<CGImage> = AsyncStream { continuation in
        addToPreviewStream = { cgImage in
            continuation.yield(cgImage)
        }
    }
    
    private var videoWriter: AVAssetWriter?
    private var videoWritingStarted = false
    private var videoWritingStartTime: CMTime?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    func pauseSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

    func resumeSession() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
}

// MARK: - Session Setup

extension CameraSessionManager {
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
        
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
            }
        }
    }
    
    func stopSessionAndCleanup() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }

            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }

            self.previewLayer = nil
            self.videoInput = nil
            self.audioInput = nil
            self.activeCamera = nil
            self.videoWriter = nil
            self.videoWriterInput = nil
            self.pixelBufferAdaptor = nil
            self.addToPreviewStream = nil
        }
    }
}

// MARK: - Session Configs

extension CameraSessionManager {
    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        try configureVideoInput()
        try configurePhotoOutput()
        try configureVideoOutput()
        try configureAudioInput()
        try configureAudioOutput()
        
        updateVideoConnectionSettings()
    }
    
    private func configureVideoInput() throws {
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
    }
    
    private func configurePhotoOutput() throws {
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    private func configureVideoOutput() throws {
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func configureAudioInput() throws {
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        guard audioStatus == .authorized,
              let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            print("Microphone access not granted, proceeding without audio")
            return
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
            self.audioInput = audioInput
        }
    }
    
    private func configureAudioOutput() throws {
        audioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }
    }
    
    private func updateVideoConnectionSettings() {
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = activeCamera?.position == .front
            }
        }
    }
}

// MARK: - Camera Controls

extension CameraSessionManager {
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
                    self.updateVideoConnectionSettings()
                } else {
                    self.captureSession.addInput(currentInput)
                }
                
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    self.previewLayer?.connection?.videoOrientation = .portrait
                }
            } catch {
                print("Camera flip failed: \(error)")
            }
        }
    }
    
    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.activeCamera else { return }
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .continuousAutoExposure
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
    
    func setZoom(_ scale: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.activeCamera else { return }
            
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor
            let newZoom = self.initialZoom * scale
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                device.videoZoomFactor = max(minZoom, min(newZoom, maxZoom))
            } catch {
                print("Zoom error: \(error)")
            }
        }
    }
    
    func updateInitialZoom() {
        guard let device = activeCamera else { return }
        initialZoom = device.videoZoomFactor
    }
    
    private func getAlternateCamera() -> AVCaptureDevice? {
        guard let currentCamera = videoInput?.device else { return nil }
        let newPosition: AVCaptureDevice.Position = currentCamera.position == .back ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
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
            
            for output in self.captureSession.outputs {
                if output != self.videoOutput {
                    self.captureSession.removeOutput(output)
                }
            }
            
            if !self.captureSession.outputs.contains(self.videoOutput),
               self.captureSession.canAddOutput(self.videoOutput)
            {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            switch type {
            case .photoCamera:
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }
            case .videoCamera:
                Task {
                    try self.configureVideoOutput()
                }
            }
        }
    }
}

// MARK: - Capture Methods

extension CameraSessionManager {
    func capturePhoto(completion: @escaping (Result<(UIImage, URL), CameraError>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let settings = AVCapturePhotoSettings()
            self.captureHandlers.photoCompletion = { result in
                switch result {
                case .success(let image):
                    let filtered = self.filterProcessor.applyFilter(to: image, filterType: self.currentFilter)
                    
                    guard let url = self.makePhotoOutputURL(),
                          let data = filtered.jpegData(compressionQuality: 1.0)
                    else {
                        completion(.failure(.fileOutputFailed))
                        return
                    }
                    
                    do {
                        try data.write(to: url)
                        completion(.success((filtered, url)))
                    } catch {
                        completion(.failure(.fileOutputFailed))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func startRecording(completion: @escaping (Result<URL, CameraError>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard let url = self.makeVideoOutputURL() else {
                completion(.failure(.fileOutputFailed))
                return
            }

            do {
                try self.setupVideoWriter(outputURL: url)
                self.videoWritingStarted = true
                self.videoWritingStartTime = nil
                self.captureHandlers.videoCompletion = completion
                DispatchQueue.main.async { self.isRecording = true }
            } catch {
                completion(.failure(.fileOutputFailed))
            }
        }
    }
    
    private func makePhotoOutputURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create a folder: \(error)")
                return nil
            }
        }
        
        let fileName = "Image-\(UUID().uuidString)-\(currentFilter).jpg"
        return documentsURL.appendingPathComponent(fileName)
    }
    
    private func makeVideoOutputURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
                
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create a folder: \(error)")
                return nil
            }
        }
        
        let fileName = "Video-\(UUID().uuidString)-\(currentFilter).mov"
        return documentsURL.appendingPathComponent(fileName)
    }

    private func setupVideoWriter(outputURL: URL) throws {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080,
            AVVideoHeightKey: 1920,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        videoInput.expectsMediaDataInRealTime = true
        
        if writer.canAdd(videoInput) {
            writer.add(videoInput)
            videoWriterInput = videoInput
        }
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 1080,
                kCVPixelBufferHeightKey as String: 1920
            ]
        )
        pixelBufferAdaptor = adaptor
        
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: audioSettings
            )
            audioInput.expectsMediaDataInRealTime = true
            
            if writer.canAdd(audioInput) {
                writer.add(audioInput)
                audioWriterInput = audioInput
            }
        }
        
        videoWriter = writer
        writer.startWriting()
    }
    
    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.videoWritingStarted else { return }

            self.videoWritingStarted = false
            self.videoWriterInput?.markAsFinished()
            self.audioWriterInput?.markAsFinished()

            self.videoWriter?.finishWriting { [weak self] in
                DispatchQueue.main.async {
                    self?.isRecording = false
                    guard let url = self?.videoWriter?.outputURL else {
                        self?.captureHandlers.videoCompletion?(.failure(.fileOutputFailed))
                        return
                    }
                    self?.captureHandlers.videoCompletion?(.success(url))
                    self?.videoWriter = nil
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
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

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraSessionManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            captureHandlers.videoCompletion?(.failure(.fileOutputFailed))
            print("Recording error: \(error.localizedDescription)")
            return
        }
        
        captureHandlers.videoCompletion?(.success(outputFileURL))
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let isVideo = output is AVCaptureVideoDataOutput

        if isVideo, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let filteredImage = filterProcessor.applyFilter(to: ciImage, filterType: currentFilter)

            let context = CIContext()
            if let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) {
                addToPreviewStream?(cgImage)
            }

            if videoWritingStarted,
               let writer = videoWriter,
               writer.status == .writing,
               let input = videoWriterInput,
               let adaptor = pixelBufferAdaptor,
               input.isReadyForMoreMediaData
            {
                if videoWritingStartTime == nil {
                    videoWritingStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    writer.startSession(atSourceTime: videoWritingStartTime!)
                }

                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let imageWidth = Int(filteredImage.extent.width)
                let imageHeight = Int(filteredImage.extent.height)
                
                var renderedBuffer: CVPixelBuffer?
                let attrs: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: imageWidth,
                    kCVPixelBufferHeightKey as String: imageHeight
                ]

                CVPixelBufferCreate(nil, imageWidth, imageHeight, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &renderedBuffer)
                if let buffer = renderedBuffer {
                    context.render(filteredImage, to: buffer)
                    adaptor.append(buffer, withPresentationTime: timestamp)
                }
            }
        }

        if !isVideo,
           videoWritingStarted,
           AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
           let input = audioWriterInput,
           input.isReadyForMoreMediaData
        {
            input.append(sampleBuffer)
        }
    }
    
    private func processFrameForRecording(filteredImage: CIImage, sampleBuffer: CMSampleBuffer, output: AVCaptureOutput) {
        guard let videoWriter = videoWriter,
              let videoWriterInput = videoWriterInput,
              videoWriter.status == .writing
        else {
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if videoWriter.status == .unknown {
            videoWriter.startSession(atSourceTime: timestamp)
            videoWritingStartTime = timestamp
            return
        }
        
        guard videoWriterInput.isReadyForMoreMediaData else {
            return
        }
        
        _ = createPixelBuffer(from: filteredImage)
        
        guard pixelBufferAdaptor != nil else { return }
        
        if output is AVCaptureAudioDataOutput,
           let audioWriterInput = audioWriterInput,
           audioWriterInput.isReadyForMoreMediaData
        {
            audioWriterInput.append(sampleBuffer)
        }
    }
    
    private func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
        let width = 1080
        let height = 1920
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        let context = CIContext()
        context.render(ciImage, to: buffer)
        
        return buffer
    }
    
    private func appendPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        to adaptor: AVAssetWriterInputPixelBufferAdaptor,
        presentationTime: CMTime
    ) {
        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}
