import AVFoundation
import UIKit

class CameraSessionManager: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var videoCompletion: ((URL) -> Void)?
    private var currentCaptureDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    var previewLayer: AVCaptureVideoPreviewLayer?

    func setupCameraSession() -> AVCaptureVideoPreviewLayer? {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            return nil
        }
        
        currentCaptureDevice = device
        
        configureSession(with: input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
        
        return previewLayer
    }
    
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }
            
            let videoInputs = self.captureSession.inputs
                .compactMap { $0 as? AVCaptureDeviceInput }
                .filter { $0.device.hasMediaType(.video) }
            
            guard let currentVideoInput = videoInputs.first else { return }
            
            self.captureSession.removeInput(currentVideoInput)
            
            let newPosition: AVCaptureDevice.Position = currentVideoInput.device.position == .back ? .front : .back
            
            guard let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: newPosition
            ),
                let newInput = try? AVCaptureDeviceInput(device: newDevice)
            else {
                self.captureSession.addInput(currentVideoInput)
                return
            }
            
            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.currentCaptureDevice = newDevice
            } else {
                self.captureSession.addInput(currentVideoInput)
            }
        }
    }
    
    func switchCameraType(to type: CameraType) {
        sessionQueue.async {
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
    
    func startRecording(completion: @escaping (URL) -> Void) {
        sessionQueue.async {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            self.videoCompletion = completion
            DispatchQueue.main.async { self.isRecording = true }
        }
    }
    
    func stopRecording() {
        sessionQueue.async {
            self.movieOutput.stopRecording()
            DispatchQueue.main.async { self.isRecording = false }
        }
    }
    
    private func configureVideoOutput() {
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }
    }
    
    private func configureSession(with input: AVCaptureDeviceInput) {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        {
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }

    func focus(at point: CGPoint) {
        guard let device = currentCaptureDevice, device.isFocusPointOfInterestSupported || device.isExposurePointOfInterestSupported else {
            return
        }
        
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
            print("Error setting focus: \(error)")
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData)
        else {
            captureCompletion?(nil)
            return
        }
        
        captureCompletion?(image)
    }
}

extension CameraSessionManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?)
    {
        if let error = error {
            print("Video recording error: \(error)")
            return
        }
        videoCompletion?(outputFileURL)
    }
}
