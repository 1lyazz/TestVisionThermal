import AVFoundation
import PhotosUI
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var videoURL: URL?
    @Published var photoURL: URL?
    @Published var selectedItem: PhotosPickerItem?
    @Published var mediaItems: [MediaItem] = []
    @Published var contentThumbnail: UIImage?
    @Published var contentName: String = "Vision Content"
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}

// MARK: - Tap On

extension HomeViewModel {
    func tapOnCameraButton() {
        hapticGen.setUpHaptic()
        coordinator.pushCameraView()
    }

    func tapOnAllHistoryButton() {
        hapticGen.setUpHaptic()
        coordinator.presentHistoryView(isSheetPresentation: true)
    }

    func tapOnProButton() {
        hapticGen.setUpHaptic()
    }

    func tapOnHistoryCell(with media: MediaItem) {
        hapticGen.setUpHaptic()

        let fileExtension = media.url.pathExtension.lowercased()
        if fileExtension == "mov" || fileExtension == "mp4" {
            coordinator.pushResultView(
                video: media.url,
                contentName: media.name
            )
        } else {
            coordinator.pushResultView(
                photo: media.thumbnail,
                photoURL: media.url,
                contentName: media.name,
                fromThumbnail: true
            )
        }
    }

    func tapOnDelete(_ item: MediaItem) {
        hapticGen.setUpHaptic()
        try? FileManager.default.removeItem(at: item.url)
        withAnimation(.default) {
            loadMediaFiles()
        }
    }
}

// MARK: - PhotosPicker

extension HomeViewModel {
    func selectItem(item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task { @MainActor in
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data)
                {
                    let filename = "Image-\(item.itemIdentifier ?? UUID().uuidString)"
                    handlePickedImage(image, contentName: filename)
                } else {
                    print("Failed to load image data.")
                }
                selectedItem = nil
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }

    @MainActor
    private func handlePickedImage(_ image: UIImage, contentName: String) {
        hapticGen.setUpHaptic()
        coordinator.pushUploadContentView(contentName: contentName, photo: image)
    }
}

// MARK: - LoadMediaFiles

extension HomeViewModel {
    func loadMediaFiles() {
        isLoading = true
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        Task.detached(priority: .background) {
            do {
                let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

                let mediaItems: [MediaItem] = try await withThrowingTaskGroup(of: MediaItem?.self) { group in
                    for url in files {
                        group.addTask {
                            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                            let creationDate = attrs?[.creationDate] as? Date ?? Date.distantPast

                            if url.pathExtension.lowercased() == "mov" || url.pathExtension.lowercased() == "mp4" {
                                let thumbnail = await self.generateThumbnail(for: url) ?? UIImage.emptyThumbnail
                                return MediaItem(url: url,
                                                 thumbnail: thumbnail,
                                                 name: String(url.lastPathComponent.prefix(14)),
                                                 creationDate: creationDate)
                            } else if let data = try? Data(contentsOf: url),
                                      let image = UIImage(data: data)
                            {
                                return MediaItem(url: url,
                                                 thumbnail: image,
                                                 name: String(url.lastPathComponent.prefix(14)),
                                                 creationDate: creationDate)
                            } else {
                                return MediaItem(url: url,
                                                 thumbnail: UIImage.emptyThumbnail,
                                                 name: String(url.lastPathComponent.prefix(14)),
                                                 creationDate: creationDate)
                            }
                        }
                    }

                    var items: [MediaItem] = []
                    for try await item in group {
                        if let item = item {
                            items.append(item)
                        }
                    }
                    return items.sorted { $0.creationDate > $1.creationDate }
                }

                await MainActor.run {
                    withAnimation(.default) {
                        self.mediaItems = mediaItems
                        if let current = self.videoURL ?? self.photoURL,
                           let index = mediaItems.firstIndex(where: { $0.url == current })
                        {
                            self.currentIndex = index
                            self.contentName = mediaItems[index].name
                            self.contentThumbnail = mediaItems[index].thumbnail
                        }
                        self.isLoading = false
                    }
                }
            } catch {
                withAnimation(.default) {
                    self.isLoading = false
                }
                print("Failed to load media files: \(error)")
            }
        }
    }

    private func generateThumbnail(for videoURL: URL) async -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timestamp = CMTime(seconds: 0, preferredTimescale: 60)

        do {
            let cgImage = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
