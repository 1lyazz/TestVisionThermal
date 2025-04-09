import SwiftUI

final class UploadContentViewModel: ObservableObject {
    @Published var contentName: String
    @Published var photo: UIImage
    @Published var photoURL: URL?
    @Published var selectedFilter: CameraFilterType = .original

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared
    private let filterProcessor = ImageFilterProcessor()
    private let originalPhoto: UIImage

    init(
        coordinator: Coordinator,
        contentName: String,
        photo: UIImage,
        photoURL: URL? = nil
    ) {
        self.coordinator = coordinator
        self.contentName = contentName
        self.photo = photo
        self.originalPhoto = photo
        self.photoURL = photoURL
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

        let filteredName = contentName + "-\(selectedFilter).jpg"

        if let url = saveImageToFileSystem(image: photo, name: filteredName) {
            photoURL = url
            coordinator.pushResultView(photo: photo, contentName: filteredName)
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
}
