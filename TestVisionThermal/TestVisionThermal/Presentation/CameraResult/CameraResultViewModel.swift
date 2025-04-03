import Photos
import SwiftUI

final class CameraResultViewModel: ObservableObject {
    @Published var photo: UIImage?
    @Published var videoURL: URL?
    @Published var isShowAlert = false
    @Published var isShowToast = false
    @Published var isOnSettingsButton = false
    @Published var videoThumbnail: UIImage?

    var alertTitle: String = ""
    var alertDescription: String = ""
    var toastTitle: String = ""

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator, photo: UIImage? = nil, videoURL: URL? = nil) {
        self.coordinator = coordinator
        self.photo = photo
        self.videoURL = videoURL

        getThumbnail()
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
                    if let photo = photo {
                        self.savePhotoToLibrary(photo: photo)
                        toastTitle = Strings.savedToGalleryTitle
                        isShowToast = true
                    } else if let videoURL = videoURL {
                        saveVideoToLibrary(videoURL)
                    }
                case .denied, .restricted, .notDetermined:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    self.isShowAlert = true

                case .limited:
                    if let photo = photo {
                        self.savePhotoToLibrary(photo: photo)
                        toastTitle = Strings.savedToGalleryTitle
                        isShowToast = true
                    } else if let videoURL = videoURL {
                        saveVideoToLibrary(videoURL)
                    }
                @unknown default:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    self.isShowAlert = true
                }
            }
        }
    }

    private func getThumbnail() {
        if let videoURL = videoURL {
            generateThumbnail(for: videoURL) { [weak self] image in
                self?.videoThumbnail = image
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

    private func savePhotoToLibrary(photo: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: photo)
        }
    }

    private func saveVideoToLibrary(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.toastTitle = Strings.savedToGalleryTitle
                    self?.isShowToast = true
                } else {
                    self?.toastTitle = Strings.savedErrorTitle
                    self?.isShowToast = true
                }
            }
        }
    }
}
