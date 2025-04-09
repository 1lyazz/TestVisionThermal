import PhotosUI
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

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
