import SwiftUI

final class HistoryViewModel: ObservableObject {
    @Published var isSheetPresentation: Bool = false

    private let coordinator: Coordinator
    private let hapticGen = HapticGen.shared

    init(coordinator: Coordinator, isSheetPresentation: Bool = false) {
        self.coordinator = coordinator
        self.isSheetPresentation = isSheetPresentation
    }

    func tapOnProButton() {
        hapticGen.setUpHaptic()
    }
    
    func tapOnCloseButton() {
        hapticGen.setUpHaptic()
        coordinator.dismissView()
    }
}
