import AVFoundation
import SwiftUI

final class VisionCameraViewModel: ObservableObject {
    @Published var isFlashOn: Bool = false
    @Published var cameraSessionManager = CameraSessionManager()
    @Published var selectCameraType: CameraType = .photoCamera
    @Published var selectedFilter: CameraFilterType = .original
    @Published var isDisableCameraButton: Bool = false
    @Published var isFrontCamera: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordingTime: TimeInterval = 0
    @Published var isShowAlert = false
    @Published var isShowToast = false
    @Published var isOnSettingsButton = true
    @Published var isMicrophoneAccess = true
    @Published var isCameraAccess = true
    @Published var isChangeCameraState = false
    
    var alertTitle: String = ""
    var alertDescription: String = ""
    var toastTitle: String = ""
    
    private var timer: Timer?
    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        checkCameraAccess()
    }
    
    func tapOnBackButton() {
        hapticGen.setUpHaptic()
        coordinator.popView()
        isRecording = false
        stopRecording()
    }
    
    func tapOnCameraButton() {
        hapticGen.setUpHaptic()
        
        switch selectCameraType {
        case .photoCamera:
            takePhoto()
        case .videoCamera:
            isRecording.toggle()
            toggleVideoRecording()
        }
    }
    
    private func takePhoto() {
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
        changeCameraStateEffect()
        isFrontCamera.toggle()
        isFlashOn = false
        cameraSessionManager.flipCamera()
    }
    
    func tapOnCameraSegmentButton(cameraType: CameraType) {
        hapticGen.setUpHaptic()
        changeCameraStateEffect()
        
        guard cameraType == .videoCamera else {
            switchToCameraType(cameraType)
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.switchToCameraType(cameraType)
                    } else {
                        self?.isMicrophoneAccess = false
                        self?.switchToCameraType(cameraType)
                        self?.alertTitle = Strings.noMicrophoneAccessTitle
                        self?.alertDescription = Strings.noMicrophoneDescription
                        self?.isShowAlert = true
                    }
                }
            }
        case .denied:
            isMicrophoneAccess = false
            switchToCameraType(cameraType)
            alertTitle = Strings.noMicrophoneAccessTitle
            alertDescription = Strings.noMicrophoneDescription
            isShowAlert = true
        case .granted:
            switchToCameraType(cameraType)
        @unknown default:
            isMicrophoneAccess = false
            switchToCameraType(cameraType)
            alertTitle = Strings.noMicrophoneAccessTitle
            alertDescription = Strings.noMicrophoneDescription
            isShowAlert = true
        }
    }
    
    private func switchToCameraType(_ cameraType: CameraType) {
        isRecording = false
        stopRecording()
        selectCameraType = cameraType
        withAnimation {
            cameraSessionManager.switchCameraType(to: cameraType)
        }
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
    
    private func toggleVideoRecording() {
        #if targetEnvironment(simulator)
        if !isRecording {
            coordinator.pushResultView(photo: .simulatorPhoto)
            stopTimer()
        } else {
            startTimer()
        }
        #else
        if cameraSessionManager.isRecording {
            stopRecording()
        } else {
            startRecording()
            if !isMicrophoneAccess {
                toastTitle = Strings.withoutAudioTitle
                isShowToast = true
            }
        }
        isDisableCameraButton = cameraSessionManager.isRecording
        
        #endif
    }
    
    private func startRecording() {
        cameraSessionManager.startRecording { [weak self] url in
            self?.coordinator.pushResultView(video: url)
        }
        startTimer()
    }
    
    private func stopRecording() {
        cameraSessionManager.stopRecording()
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        recordingTime = 0
    }
    
    private func checkCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                DispatchQueue.main.async {
                    self?.isCameraAccess = status
                }
            }
        case .authorized:
            isCameraAccess = true
        case .denied, .restricted:
            isCameraAccess = false
        @unknown default:
            isCameraAccess = false
        }
    }
    
    private func changeCameraStateEffect() {
        withAnimation {
            isChangeCameraState = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isChangeCameraState = false
            }
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
    
    var formattedRecordingTime: String {
        let totalSeconds = Int(recordingTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
