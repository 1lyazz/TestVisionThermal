import SwiftUI

final class SettingsViewModel: ObservableObject {
    var coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
