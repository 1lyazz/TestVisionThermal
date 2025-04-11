import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var settingsType: SettingsType = .contact
    @Published var isListVisible = false

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    func tapOnProButton() {
        hapticGen.setUpHaptic()
    }

    func tapOnSettingsButton(type: SettingsType) {
        hapticGen.setUpHaptic()

        switch type {
        case .contact: MailSheet.shared.presentMailSheet()
        case .share: break
        case .restore: print("restore")
        case .rate: break
        case .privacy: break
        case .terms: break
        }
    }
}
