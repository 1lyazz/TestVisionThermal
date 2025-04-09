import SwiftUI

final class HomeViewModel: ObservableObject {
    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}

extension HomeViewModel {
    func tapOnCameraButton() {
        hapticGen.setUpHaptic()
        coordinator.pushCameraView()
    }

    func tapOnPhotosButton() {
        hapticGen.setUpHaptic()
        coordinator.pushUploadContentView(contentName: "Image-123321", photo: .simulatorPhoto)
    }

    func tapOnAllHistoryButton() {
        hapticGen.setUpHaptic()
        coordinator.presentHistoryView()
    }
}
