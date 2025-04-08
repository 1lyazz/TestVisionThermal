import UIKit

struct CaptureHandlers {
    var photoCompletion: ((Result<UIImage, CameraError>) -> Void)?
    var videoCompletion: ((Result<URL, CameraError>) -> Void)?
}
