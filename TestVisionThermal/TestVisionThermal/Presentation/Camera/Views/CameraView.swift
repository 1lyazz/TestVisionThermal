import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraSessionManager: CameraSessionManager

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        if let cameraLayer = cameraSessionManager.setupCameraSession() {
            cameraLayer.frame = viewController.view.bounds
            cameraLayer.videoGravity = .resizeAspectFill
            viewController.view.layer.addSublayer(cameraLayer)
        }

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        viewController.view.addGestureRecognizer(tapGesture)
        viewController.view.isUserInteractionEnabled = true

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        cameraSessionManager.previewLayer?.frame = uiViewController.view.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(cameraSessionManager: cameraSessionManager)
    }

    final class Coordinator: NSObject {
        private let cameraSessionManager: CameraSessionManager

        init(cameraSessionManager: CameraSessionManager) {
            self.cameraSessionManager = cameraSessionManager
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view,
                  let previewLayer = cameraSessionManager.previewLayer else { return }

            let location = gesture.location(in: view)
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
            cameraSessionManager.focus(at: devicePoint)

            showFocusIndicator(at: location, in: view)
        }

        private func showFocusIndicator(at location: CGPoint, in view: UIView) {
            let focusView = FocusIndicatorView(frame: CGRect(origin: .zero, size: CGSize(width: 70, height: 70)))
            focusView.center = location
            view.addSubview(focusView)

            UIView.animate(withDuration: 0.5, animations: {
                focusView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
    }
}

final class FocusIndicatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAppearance() {
        backgroundColor = .clear
        layer.borderColor = UIColor.primaryB827CE.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
    }
}
