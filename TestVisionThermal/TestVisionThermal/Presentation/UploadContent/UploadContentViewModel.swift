import SwiftUI

final class UploadContentViewModel: ObservableObject {
    @Published var contentName: String
    @Published var photo: UIImage
    @Published var photoURL: URL?
    @Published var selectedFilter: CameraFilterType = .original
    @Published var isEdit: Bool = false

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared
    private let filterProcessor = ImageFilterProcessor()
    private var originalPhoto: UIImage

    init(
        coordinator: Coordinator,
        contentName: String,
        photo: UIImage,
        photoURL: URL? = nil,
        isEdit: Bool
    ) {
        self.coordinator = coordinator
        self.contentName = contentName
        self.photo = photo
        self.originalPhoto = photo
        self.photoURL = photoURL
        self.isEdit = isEdit

        if isEdit {
            let baseName = (contentName as NSString).deletingPathExtension

            if let range = baseName.range(of: "-", options: .backwards) {
                let trimmedBase = String(baseName[..<range.lowerBound])
                let originalName = trimmedBase + "-original.jpg"

                if let loadedOriginal = Self.loadOriginalPhotoFromOriginalFolder(name: originalName) {
                    self.photo = loadedOriginal
                    self.originalPhoto = loadedOriginal
                } else {
                    print("Failed to load original photo from storage, using provided photo.")
                }
            } else {
                let originalName = baseName + "-original.jpg"

                if let loadedOriginal = Self.loadOriginalPhotoFromOriginalFolder(name: originalName) {
                    self.photo = loadedOriginal
                    self.originalPhoto = loadedOriginal
                } else {
                    print("Failed to load original photo from storage, using provided photo.")
                }
            }
        }
    }
}

extension UploadContentViewModel {
    func tapOnBackButton() {
        hapticGen.setUpHaptic()
        coordinator.popView()
    }

    func tapOnFilterButton(filterType: CameraFilterType) {
        hapticGen.setUpHaptic()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            withAnimation {
                self.selectedFilter = filterType
                let filtered = self.filterProcessor.applyFilter(to: self.originalPhoto, filterType: filterType)
                self.photo = filtered
            }
        }
    }

    func tapOnContinueButton() {
        hapticGen.setUpHaptic()
        let filteredName: String

        if isEdit {
            let baseName = (contentName as NSString).deletingPathExtension
            let originalName: String
            if let range = baseName.range(of: "-", options: .backwards) {
                let trimmedBase = String(baseName[..<range.lowerBound])
                originalName = trimmedBase + "-\(selectedFilter).jpg"
            } else {
                originalName = baseName + "-\(selectedFilter).jpg"
            }

            filteredName = originalName

        } else {
            filteredName = contentName + "-\(selectedFilter).jpg"
        }

        if let url = saveImageToFileSystem(image: photo, name: filteredName) {
            photoURL = url
            coordinator.pushResultView(photo: photo, contentName: filteredName, fromUpload: true)
            if isEdit {
                let baseName = (contentName as NSString).deletingPathExtension
                let originalName: String
                if let range = baseName.range(of: "-", options: .backwards) {
                    let trimmedBase = String(baseName[..<range.lowerBound])
                    originalName = trimmedBase + "-original.jpg"
                } else {
                    originalName = baseName + "-original.jpg"
                }

                saveOriginalPhotoToOriginalFolder(name: originalName)
            } else {
                saveOriginalPhotoToOriginalFolder(name: contentName + "-original.jpg")
            }
        } else {
            print("Failed to save image")
        }
    }

    func swipeLeftToNextFilter() {
        guard let currentIndex = CameraFilterType.allCases.firstIndex(of: selectedFilter) else { return }
        let nextIndex = currentIndex + 1
        guard CameraFilterType.allCases.indices.contains(nextIndex) else { return }

        let nextFilter = CameraFilterType.allCases[nextIndex]
        tapOnFilterButton(filterType: nextFilter)
    }

    func swipeRightToPreviousFilter() {
        guard let currentIndex = CameraFilterType.allCases.firstIndex(of: selectedFilter) else { return }
        let previousIndex = currentIndex - 1
        guard CameraFilterType.allCases.indices.contains(previousIndex) else { return }

        let previousFilter = CameraFilterType.allCases[previousIndex]
        tapOnFilterButton(filterType: previousFilter)
    }
}

private extension UploadContentViewModel {
    private func saveImageToFileSystem(image: UIImage, name: String) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        let filename = name.replacingOccurrences(of: " ", with: "_")
        let fileManager = FileManager.default

        do {
            let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = directory.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }

            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image to file system: \(error)")
            return nil
        }
    }

    private func saveOriginalPhotoToOriginalFolder(name: String) {
        guard let data = originalPhoto.jpegData(compressionQuality: 0.9) else { return }

        let filename = name.replacingOccurrences(of: " ", with: "_")
        let fileManager = FileManager.default

        do {
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let originalFolderURL = documentsDirectory.appendingPathComponent("Original")

            if !fileManager.fileExists(atPath: originalFolderURL.path) {
                try fileManager.createDirectory(at: originalFolderURL, withIntermediateDirectories: true, attributes: nil)
            }

            let fileURL = originalFolderURL.appendingPathComponent(filename)

            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }

            try data.write(to: fileURL)
        } catch {
            print("Error saving original photo: \(error)")
        }
    }

    private static func loadOriginalPhotoFromOriginalFolder(name: String) -> UIImage? {
        let filename = name.replacingOccurrences(of: " ", with: "_")
        let fileManager = FileManager.default

        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let originalFolderURL = documentsDirectory.appendingPathComponent("Original")
        let fileURL = originalFolderURL.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Original image not found at path: \(fileURL.path)")
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data)
        else {
            print("Failed to read original image data from file.")
            return nil
        }

        return image
    }
}
