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

extension CameraFilterType {
    var coreImageFilter: CIFilter? {
        switch self {
        case .original:
            return nil
        case .thermal:
            return CIFilter()
        case .heat:
            return CIFilter(name: "CIThermal")
        case .night:
            return CIFilter()
        case .xRay:
            let xRayFilter = CIFilter.xRay()
            return xRayFilter
        case .glitch:
            let filter = CIFilter.hueAdjust()
            filter.angle = 5
            return filter
        case .halftone:
            return CIFilter(name: "CICMYKHalftone")
        case .invert:
            return CIFilter(name: "CIColorInvert")
        case .noir:
            return CIFilter(name: "CIPhotoEffectNoir")
        case .neon:
            return CIFilter(name: "CIColorInvert")
        case .chrome:
            return CIFilter(name: "CIPhotoEffectChrome")
        case .spotColor:
            return CIFilter(name: "CISpotColor")
        case .draw:
            return CIFilter(name: "CIEdgeWork")
        case .blur:
            return CIFilter(name: "CIDiscBlur")
        case .motionBlur:
            return CIFilter(name: "CIMotionBlur")
        case .pixel:
            return CIFilter(name: "CIPixellate")
        case .circlePixel:
            return CIFilter(name: "CIHexagonalPixellate")
        case .crystallizePixel:
            return CIFilter(name: "CICrystallize")
        }
    }

    var coreImageFilters: [CIFilter] {
        guard let filter = coreImageFilter else { return [] }
        return [filter]
    }
}
