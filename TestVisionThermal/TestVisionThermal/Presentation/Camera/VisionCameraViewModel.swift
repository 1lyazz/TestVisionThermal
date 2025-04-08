import AVFoundation
import SwiftUI

final class VisionCameraViewModel: ObservableObject {
    @Published var isFlashOn: Bool = false
    @Published var cameraSessionManager = CameraSessionManager()
    @Published var selectCameraType: CameraType = .photoCamera
    @Published var selectedFilter: CameraFilterType = .original
    @Published var isDisableCameraButton: Bool = false
    @Published var isFrontCamera: Bool = false
    @Published var recordingTime: TimeInterval = 0
    @Published var isShowAlert = false
    @Published var isShowToast = false
    @Published var isOnSettingsButton = true
    @Published var isMicrophoneAccess = true
    @Published var isCameraAccess = true
    @Published var isChangeCameraState = false
    @Published var cameraError: CameraError?
    @Published var isCameraVisible: Bool = true
    @Published var lastContentURL: URL?
    @Published var lastContentName: String?
    @Published var contentThumbnail: UIImage?
    @Published var isDeinit: Bool = true
    @Published var isRecording: Bool = false {
        didSet {
            coordinator.navigationController.interactivePopGestureRecognizer?.isEnabled = !isRecording
        }
    }

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
    
    deinit {
        isDeinit = true
        turnOffFlash()
        isCameraVisible = false
    }
    
    func tapOnBackButton() {
        isDeinit = true
        hapticGen.setUpHaptic()
        turnOffFlash()
        isCameraVisible = false
        coordinator.popView()
        isRecording = false
        stopRecording()
    }
    
    func tapOnCameraButton() {
        hapticGen.setUpHaptic()
        
        switch selectCameraType {
        case .photoCamera:
            isDeinit = false
            takePhoto()
        case .videoCamera:
            isRecording.toggle()
            toggleVideoRecording()
        }
    }
    
    private func takePhoto() {
        isDisableCameraButton = true
        
        #if targetEnvironment(simulator)
        coordinator.pushResultView(photo: .simulatorPhoto, contentName: "Image-123312")
        #else
        DispatchQueue.main.async { [weak self] in
            self?.cameraSessionManager.capturePhoto { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success((let image, let url)):
                    let contentName = url.lastPathComponent
                    self.coordinator.pushResultView(photo: image, contentName: contentName)
                    self.lastContentURL = url
                    self.lastContentName = contentName
                    self.loadLastSavedContentURL(for: selectCameraType)
                case .failure(let error):
                    self.alertTitle = Strings.goSettingsButtonTitle
                    self.alertDescription = error.localizedDescription
                    self.isShowAlert = true
                }
                self.isDisableCameraButton = false
            }
        }
        #endif
    }
    
    func tapOnThumbnail() {
        isDeinit = false
        hapticGen.setUpHaptic()
        
        if selectCameraType == .photoCamera {
            coordinator.pushResultView(
                photo: contentThumbnail,
                photoURL: lastContentURL,
                contentName: lastContentName ?? "",
                fromThumbnail: true
            )
        } else {
            coordinator.pushResultView(
                video: lastContentURL,
                contentName: lastContentName ?? "",
                fromThumbnail: true
            )
        }
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
        isFlashOn = false
        
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
                    }
                }
            }
        case .denied:
            isMicrophoneAccess = false
            switchToCameraType(cameraType)
            alertTitle = Strings.noMicrophoneAccessTitle
            alertDescription = Strings.noMicrophoneDescription
        case .granted:
            switchToCameraType(cameraType)
        @unknown default:
            isMicrophoneAccess = false
            switchToCameraType(cameraType)
            alertTitle = Strings.noMicrophoneAccessTitle
            alertDescription = Strings.noMicrophoneDescription
        }
    }
    
    private func switchToCameraType(_ cameraType: CameraType) {
        isRecording = false
        stopRecording()
        selectCameraType = cameraType
        withAnimation {
            cameraSessionManager.switchCameraType(to: cameraType)
        }
        
        loadLastSavedContentURL(for: cameraType)
    }
    
    func tapOnFilterButton(filterType: CameraFilterType) {
        hapticGen.setUpHaptic()
        
        DispatchQueue.main.async { [weak self] in
            withAnimation {
                self?.selectedFilter = filterType
                self?.cameraSessionManager.setCurrentFilter(filterType)
            }
        }
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
    
    func turnOffFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isFlashOn = false
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to turn off flash: \(error)")
        }
    }
    
    func loadLastSavedContentURL(for type: CameraType) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let folderName = (type == .photoCamera) ? "Photos" : "Videos"
        let mediaExtensions = (type == .photoCamera) ? ["jpg", "jpeg", "png"] : ["mov", "mp4"]

        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)

            let mediaFiles = fileURLs.filter { mediaExtensions.contains($0.pathExtension.lowercased()) }

            let sortedFiles = try mediaFiles.sorted {
                let attr1 = try $0.resourceValues(forKeys: [.contentModificationDateKey])
                let attr2 = try $1.resourceValues(forKeys: [.contentModificationDateKey])
                return (attr1.contentModificationDate ?? .distantPast) > (attr2.contentModificationDate ?? .distantPast)
            }

            if let lastFile = sortedFiles.first {
                DispatchQueue.main.async { [weak self] in
                    self?.lastContentURL = lastFile
                    self?.lastContentName = lastFile.lastPathComponent

                    switch type {
                    case .photoCamera:
                        if let image = UIImage(contentsOfFile: lastFile.path) {
                            self?.contentThumbnail = image
                        } else {
                            self?.contentThumbnail = nil
                        }

                    case .videoCamera:
                        self?.generateThumbnail(for: lastFile) { [weak self] image in
                            self?.contentThumbnail = image
                        }
                    }
                }
            }
        } catch {
            print("Error loading the contents of a folder \(folderName): \(error.localizedDescription)")
        }
    }
    
    func applicationWillResignActive() {
        if isRecording {
            isRecording = false
            stopRecording()
        }
        
        cameraSessionManager.pauseSession()
        withAnimation {
            isChangeCameraState = true
        }
    }

    func applicationDidBecomeActive() {
        changeCameraStateEffect()
        cameraSessionManager.resumeSession()
    }
    
    private func toggleVideoRecording() {
        #if targetEnvironment(simulator)
        if !isRecording {
            coordinator.pushResultView(photo: .simulatorPhoto, contentName: "Video-123321")
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
        cameraSessionManager.startRecording { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let url):
                self.isDeinit = false
                let contentName = url.lastPathComponent
                self.coordinator.pushResultView(video: url, contentName: contentName)
                self.lastContentURL = url
                self.lastContentName = contentName
                self.loadLastSavedContentURL(for: selectCameraType)
            case .failure(let error):
                self.alertTitle = Strings.wrongAccessTitle
                self.alertDescription = error.localizedDescription
                self.isShowAlert = true
            }
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

    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            let timestamp = CMTime(seconds: 0, preferredTimescale: 60)

            do {
                let cgImage = try generator.copyCGImage(at: timestamp, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
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
