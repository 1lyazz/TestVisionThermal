import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraSessionManager: CameraSessionManager
    @Binding var error: CameraError?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        
        cameraSessionManager.setupSession { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Task {
                        await processPreviewFrames(imageView: imageView)
                    }
                case .failure(let error):
                    self.error = error
                }
            }
        }
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        viewController.view.addGestureRecognizer(tapGesture)
        viewController.view.isUserInteractionEnabled = true
        
        return viewController
    }
    
    private func processPreviewFrames(imageView: UIImageView) async {
        for await cgImage in cameraSessionManager.previewStream {
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraSessionManager: cameraSessionManager)
    }
    
    final class Coordinator: NSObject {
        private let cameraSessionManager: CameraSessionManager
        
        init(cameraSessionManager: CameraSessionManager) {
            self.cameraSessionManager = cameraSessionManager
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            
            let location = gesture.location(in: view)
            let devicePoint = CGPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )
            
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
