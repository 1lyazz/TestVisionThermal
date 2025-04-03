enum CameraError: Error {
    case configurationFailed
    case permissionDenied
    case deviceSetupFailed
    case captureFailed
    case fileOutputFailed
    case unknown
}
