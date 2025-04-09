import Photos
import SwiftUI

final class CameraResultViewModel: ObservableObject {
    @Published var photo: UIImage?
    @Published var videoURL: URL?
    @Published var photoURL: URL?
    @Published var contentName: String
    @Published var isShowAlert = false
    @Published var isShowToast = false
    @Published var isOnSettingsButton = true
    @Published var videoThumbnail: UIImage?
    @Published var fromThumbnail: Bool = false
    @Published var alertType: AlertType = .ok
    @Published var mediaItems: [URL] = []
    @Published var currentIndex: Int = 0

    var alertTitle: String = ""
    var alertDescription: String = ""
    var toastTitle: String = ""

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator, photo: UIImage? = nil, videoURL: URL? = nil, photoURL: URL? = nil, contentName: String, fromThumbnail: Bool) {
        self.coordinator = coordinator
        self.photo = photo
        self.videoURL = videoURL
        self.photoURL = photoURL
        self.contentName = contentName
        self.fromThumbnail = fromThumbnail

        loadMediaFiles()
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
                        toastTitle = Strings.savedToPhotosTitle
                        isShowToast = true
                    } else if let videoURL = videoURL {
                        saveVideoToLibrary(videoURL)
                    }
                case .denied, .restricted, .notDetermined:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    self.alertType = .ok
                    self.isShowAlert = true

                case .limited:
                    if let photo = photo {
                        self.savePhotoToLibrary(photo: photo)
                        toastTitle = Strings.savedToPhotosTitle
                        isShowToast = true
                    } else if let videoURL = videoURL {
                        saveVideoToLibrary(videoURL)
                    }
                @unknown default:
                    self.alertTitle = Strings.noPhotosAccessTitle
                    self.alertDescription = Strings.noPhotosAccessDescription
                    self.alertType = .ok
                    self.isShowAlert = true
                }
            }
        }
    }

    func tapOnDeleteButton() {
        hapticGen.setUpHaptic()
        alertTitle = Strings.deleteAlertTitle
        alertDescription = Strings.deleteAlertDescription
        alertType = .cancel
        isShowAlert = true
    }

    func deleteContent() {
        let fileToDelete = mediaItems[currentIndex]

        try? FileManager.default.removeItem(at: fileToDelete)
        mediaItems.remove(at: currentIndex)

        if mediaItems.isEmpty {
            coordinator.popView()
            return
        }

        if currentIndex >= mediaItems.count {
            currentIndex = mediaItems.count - 1
        }

        loadMedia(at: currentIndex)
    }

    func showNextMedia() {
        guard currentIndex < mediaItems.count - 1 else { return }
        currentIndex += 1
        loadMedia(at: currentIndex)
    }

    func showPreviousMedia() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadMedia(at: currentIndex)
    }

    private func loadMedia(at index: Int) {
        guard mediaItems.indices.contains(index) else {
            print("Invalid index: \(index)")
            return
        }

        let url = mediaItems[index]
        contentName = url.lastPathComponent

        if url.pathExtension.lowercased() == "mov" || url.pathExtension.lowercased() == "mp4" {
            videoURL = url
            photo = nil
            getThumbnail()
        } else {
            videoURL = nil
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                photo = image
            } else {
                print("Failed to load image at: \(url)")
            }
        }
    }

    private func loadMediaFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let sorted = files.sorted {
                let attrs1 = try? FileManager.default.attributesOfItem(atPath: $0.path)
                let attrs2 = try? FileManager.default.attributesOfItem(atPath: $1.path)

                let date1 = attrs1?[.creationDate] as? Date ?? .distantPast
                let date2 = attrs2?[.creationDate] as? Date ?? .distantPast

                return date1 > date2
            }

            mediaItems = sorted
            if let current = videoURL ?? photoURL,
               let index = sorted.firstIndex(of: current)
            {
                currentIndex = index
            }
        } catch {
            print("Failed to load media files: \(error)")
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
                    self?.toastTitle = Strings.savedToPhotosTitle
                    self?.isShowToast = true
                } else {
                    self?.toastTitle = Strings.savedErrorTitle
                    self?.isShowToast = true
                }
            }
        }
    }
}
