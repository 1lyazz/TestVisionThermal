enum CameraType: String, CaseIterable {
    case photoCamera
    case videoCamera

    var cameraIcon: ImageResource {
        switch self {
            case .photoCamera: .photoCameraIcon
            case .videoCamera: .videoCameraIcon
        }
    }
}
