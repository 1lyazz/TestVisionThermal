import SwiftUI

final class ScreenSizer {
    static let shared = ScreenSizer()

    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    func isSmallScreenHeight(_ height: CGFloat = 700) -> Bool {
        screenHeight < height
    }
}
