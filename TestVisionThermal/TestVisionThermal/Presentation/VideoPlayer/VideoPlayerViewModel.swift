import AVKit
import SwiftUI

class PlayerViewModel: ObservableObject {
    var player: AVPlayer?

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }
}
