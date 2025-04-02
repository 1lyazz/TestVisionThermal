import AVFoundation
import SwiftUI

final class VisionCameraViewModel: ObservableObject {
    @Published var isFlashOn: Bool = false
    @Published var cameraSessionManager = CameraSessionManager()
    @Published var selectCameraType: CameraType = .photoCamera
    @Published var selectedFilter: CameraFilterType = .original
    @Published var isDisableCameraButton: Bool = false
    @Published var isFrontCamera: Bool = false
    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    func tapOnBackButton() {
        hapticGen.setUpHaptic()
        coordinator.popView()
    }
    
    func tapOnCameraButton() {
        hapticGen.setUpHaptic()
        isDisableCameraButton = true
        
        #if targetEnvironment(simulator)
        coordinator.pushResultView(photo: .simulatorPhoto)
        #else
        DispatchQueue.main.async { [weak self] in
            self?.cameraSessionManager.capturePhoto { [weak self] image in
                guard let self = self else { return }
        
                if let image = image {
                    self.coordinator.pushResultView(photo: image)
                } else {
                    self.coordinator.pushResultView(photo: .simulatorPhoto)
                }
                self.isDisableCameraButton = false
            }
        }
        #endif
    }
    
    func tapOnFlipButton() {
        hapticGen.setUpHaptic()
        isFrontCamera.toggle()
        isFlashOn = false
        cameraSessionManager.switchCamera()
    }
    
    func tapOnSegmentButton(cameraType: CameraType) {
        hapticGen.setUpHaptic()
        selectCameraType = cameraType
    }
    
    func tapOnFilterButton(filterType: CameraFilterType) {
        hapticGen.setUpHaptic()
        selectedFilter = filterType
    }
    
    func tapOnFlashButton() {
        hapticGen.setUpHaptic()
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.hasTorch {
                if isFlashOn {
                    device.torchMode = .off
                } else {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
                isFlashOn.toggle()
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flash error: \(error)")
        }
    }
    
    var segmentOffset: CGFloat {
        switch selectCameraType {
        case .photoCamera:
            return -20
        case .videoCamera:
            return 20
        }
    }
}
