import SwiftUI

final class SettingsViewModel: ObservableObject {
    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    func tapOnProButton() {
        hapticGen.setUpHaptic()
    }
}
