import SwiftUI

final class SplashScreenViewModel: ObservableObject {
    @Published var isSplashAnimation: Bool = false
    private var coordinator: StartAppCoordinator

    init(coordinator: StartAppCoordinator) {
        self.coordinator = coordinator
    }

    func setupAppNavigation() async {
        await coordinator.handleSplashCompletion()
    }
}
