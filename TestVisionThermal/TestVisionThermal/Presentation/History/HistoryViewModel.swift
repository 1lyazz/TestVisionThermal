import SwiftUI

final class HistoryViewModel: ObservableObject {
    var coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
