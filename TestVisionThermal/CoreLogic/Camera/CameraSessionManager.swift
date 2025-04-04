import AVFoundation
import UIKit

class CameraSessionManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var currentCaptureDevice: AVCaptureDevice?
    
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
    
    private func configureSession(with input: AVCaptureDeviceInput) {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
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
