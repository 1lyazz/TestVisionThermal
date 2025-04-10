import PhotosUI
import SwiftUI

final class HistoryViewModel: ObservableObject {
    @Published var videoURL: URL?
    @Published var photoURL: URL?
    @Published var isSheetPresentation: Bool = false
    @Published var mediaItems: [MediaItem] = []
    @Published var selectedFilter: HistoryFilterType = .all
    @Published var isLoading: Bool = false
    @Published var contentThumbnail: UIImage?
    @Published var contentName: String = "Vision Content"
    @Published var currentIndex: Int = 0

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    var filteredMediaItems: [MediaItem] {
        switch selectedFilter {
        case .all:
            return mediaItems
        case .filter(let filterType):
            return mediaItems.filter { item in
                let name = item.name.lowercased()
                let keyword = filterType.rawValue.lowercased()
                return name.hasSuffix(keyword) || name.contains("-\(keyword)")
            }
        }
    }

    init(coordinator: Coordinator, isSheetPresentation: Bool = false) {
        self.coordinator = coordinator
        self.isSheetPresentation = isSheetPresentation
    }
}

// MARK: - Tap On

extension HistoryViewModel {
    func tapOnProButton() {
        hapticGen.setUpHaptic()
    }

    func tapOnCloseButton() {
        hapticGen.setUpHaptic()
        coordinator.dismissView()
    }

    func tapOnCameraButton() {
        hapticGen.setUpHaptic()

        if isSheetPresentation {
            coordinator.dismissView()
        }

        coordinator.pushCameraView()
    }

    func tapOnFilterButton(filterType: HistoryFilterType) {
        hapticGen.setUpHaptic()

        selectedFilter = filterType
    }

    func tapOnHistoryCell(with media: MediaItem) {
        hapticGen.setUpHaptic()

        let fileExtension = media.url.pathExtension.lowercased()
        if fileExtension == "mov" || fileExtension == "mp4" {
            coordinator.pushResultView(
                video: media.url,
                contentName: media.name,
                fromThumbnail: true
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

    func tapOnEdit(_ item: MediaItem) {
        hapticGen.setUpHaptic()
        coordinator.pushUploadContentView(contentName: item.name, photo: item.thumbnail, photoURL: item.url, isEdit: true)
    }
}

// MARK: - LoadMediaFiles

extension HistoryViewModel {
    func loadMediaFiles() {
        isLoading = true
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        Task.detached(priority: .background) {
            do {
                let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.isDirectoryKey], options: [])
                let filteredFiles = files.filter { url in
                    if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                       let isDirectory = resourceValues.isDirectory
                    {
                        return !isDirectory
                    }
                    return true
                }

                let mediaItems: [MediaItem] = try await withThrowingTaskGroup(of: MediaItem?.self) { group in
                    for url in filteredFiles {
                        group.addTask {
                            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                            let creationDate = attrs?[.creationDate] as? Date ?? Date.distantPast

                            if url.pathExtension.lowercased() == "mov" || url.pathExtension.lowercased() == "mp4" {
                                let thumbnail = await self.generateThumbnail(for: url) ?? UIImage.emptyThumbnail
                                return MediaItem(url: url,
                                                 thumbnail: thumbnail,
                                                 name: String(url.lastPathComponent),
                                                 creationDate: creationDate)
                            } else if let data = try? Data(contentsOf: url),
                                      let image = UIImage(data: data)
                            {
                                return MediaItem(url: url,
                                                 thumbnail: image,
                                                 name: String(url.lastPathComponent),
                                                 creationDate: creationDate)
                            } else {
                                return MediaItem(url: url,
                                                 thumbnail: UIImage.emptyThumbnail,
                                                 name: String(url.lastPathComponent),
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
