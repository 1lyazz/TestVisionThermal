import SwiftUI

final class UploadContentViewModel: ObservableObject {
    @Published var contentName: String
    @Published var photo: UIImage
    @Published var photoURL: URL?
    @Published var selectedFilter: CameraFilterType = .original

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(
        coordinator: Coordinator,
        contentName: String,
        photo: UIImage,
        photoURL: URL? = nil
    ) {
        self.coordinator = coordinator
        self.contentName = contentName
        self.photo = photo
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
            withAnimation {
                self?.selectedFilter = filterType
            }
        }
    }

    func tapOnContinueButton() {
        hapticGen.setUpHaptic()
    }
}
