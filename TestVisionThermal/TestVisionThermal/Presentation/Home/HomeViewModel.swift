import SwiftUI

final class HomeViewModel: ObservableObject {
    var coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
