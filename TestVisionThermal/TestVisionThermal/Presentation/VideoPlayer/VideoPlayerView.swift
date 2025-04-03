import AVKit
import SwiftUI

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL
    var autoPlay: Bool = true
    @StateObject var viewModel = PlayerViewModel()

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        viewModel.player = player
        controller.player = player
        controller.showsPlaybackControls = true

        if autoPlay {
            viewModel.play()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
