import Photos
import SwiftUI

final class CameraResultViewModel: ObservableObject {
    @Published var photo: UIImage
    @Published var isShowAlert: Bool = false
    @Published var isOnSettingsButton: Bool = false

    var alertTitle: String = ""
    var alertDescription: String = ""

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator, photo: UIImage) {
        self.coordinator = coordinator
        self.photo = photo
    }

    func tapOnBackButton() {
        hapticGen.setUpHaptic()
        coordinator.popView()
    }

    func tapOnSaveButton() {
        hapticGen.setUpHaptic()

        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                switch status {
                case .authorized:
//                    self.showLoadDrawingArAlert()
                    self.savePhotoToLibrary()
                case .denied, .restricted, .notDetermined:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    withAnimation {
                        self.isShowAlert = true
                    }
                case .limited:
//                    self.showLoadDrawingArAlert()
                    self.savePhotoToLibrary()
                @unknown default:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    withAnimation {
                        self.isShowAlert = true
                    }
                }
            }
        }
    }

    private func savePhotoToLibrary() {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self.photo)
        }
    }
}
