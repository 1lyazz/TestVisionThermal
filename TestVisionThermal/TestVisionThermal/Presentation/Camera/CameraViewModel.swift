import SwiftUI

final class CameraViewModel: ObservableObject {
    var coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
