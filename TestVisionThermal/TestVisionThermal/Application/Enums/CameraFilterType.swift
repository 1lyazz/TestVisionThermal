import CoreImage.CIFilterBuiltins

enum CameraFilterType: String, CaseIterable {
    case original
    case thermal
    case heat
    case night
    case xRay
    case glitch
    case noir
    case neon
    case chrome
    case spotColor
    case draw
    case halftone
    case invert
    case blur
    case motionBlur
    case pixel
    case circlePixel
    case crystallizePixel

    var title: String {
        switch self {
            case .original: "Original"
            case .thermal: "Thermal"
            case .heat: "Heat"
            case .night: "Night Vision"
            case .xRay: "X-ray"
            case .glitch: "Glitch"
            case .noir: "Noir"
            case .neon: "Neon"
            case .chrome: "Chrome"
            case .spotColor: "Spot Color"
            case .draw: "Draw"
            case .halftone: "Halftone"
            case .invert: "Invert"
            case .blur: "Blur"
            case .motionBlur: "Motion Blur"
            case .pixel: "Pixel"
            case .circlePixel: "Circle Pixel"
            case .crystallizePixel: "Crystallize"
        }
    }
}
