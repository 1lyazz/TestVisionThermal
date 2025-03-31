import SwiftUI

final class TabBarViewModel: ObservableObject {
    @Published var selectedIndex: Int = 0
    
    let coordinator: Coordinator
    private let hapticGen = HapticGen.shared
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        setupSubscribes()
    }
    
    private func setupSubscribes() {
        hapticGen.setUpHaptic()
        coordinator.$selectionTabBar
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$selectedIndex)
    }
}
