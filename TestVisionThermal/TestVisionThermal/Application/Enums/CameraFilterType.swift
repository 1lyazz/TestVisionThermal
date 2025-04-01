enum CameraFilterType: String, CaseIterable {
    case original
    case thermal
    case night
    case xRay
    case glitch

    var title: String {
        switch self {
            case .original: "Original"
            case .thermal: "Thermal"
            case .night: "Night Vision"
            case .xRay: "X-ray"
            case .glitch: "Glitch"
        }
    }
}
