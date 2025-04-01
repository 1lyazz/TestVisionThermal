import SwiftUI

final class HapticGen {
    static let shared = HapticGen()

    private let hapticGen = UIImpactFeedbackGenerator(style: .rigid)

    private init() {
        hapticGen.prepare()
    }

    func setUpHaptic(_ intensity: CGFloat = 0.6) {
        hapticGen.impactOccurred(intensity: intensity)
    }
}
