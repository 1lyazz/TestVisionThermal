import CoreImage
import UIKit

final class ImageFilterProcessor {
    func applyFilter(to image: UIImage, filterType: CameraFilterType) -> UIImage {
        guard filterType != .original,
              let ciImage = CIImage(image: image)
        else {
            return image
        }
        
        let context = CIContext(options: nil)
        var outputImage: CIImage = ciImage
        
        switch filterType {
        case .thermal:
            let gradientColors = [
                UIColor.blue.cgColor,
                UIColor.green.cgColor,
                UIColor.yellow.cgColor,
                UIColor.red.cgColor
            ]
            
            let gradientLocations: [CGFloat] = [0.0, 0.15, 0.25, 0.35, 1.0]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: gradientColors as CFArray,
                                      locations: gradientLocations)
            
            let gradientSize = CGSize(width: 256, height: 1)
            UIGraphicsBeginImageContext(gradientSize)
            let context = UIGraphicsGetCurrentContext()
            context?.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: gradientSize.width, y: 0),
                options: []
            )
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let gradientCIImage = CIImage(image: gradientImage!) else {
                return UIImage()
            }
            
            if let colorMap = CIFilter(name: "CIColorMap") {
                colorMap.setValue(ciImage, forKey: kCIInputImageKey)
                colorMap.setValue(gradientCIImage, forKey: "inputGradientImage")
                if let colorMap = colorMap.outputImage {
                    outputImage = colorMap
                }
            }
            
        case .night:
            if let contrastFilter = CIFilter(name: "CIColorControls") {
                contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
                contrastFilter.setValue(2.0, forKey: kCIInputContrastKey)
                if let contrasted = contrastFilter.outputImage {
                    outputImage = contrasted
                }
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.0, green: 1.0, blue: 0.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let mono = monoFilter.outputImage {
                    outputImage = mono
                }
            }
            
            if let noiseFilter = CIFilter(name: "CINoiseReduction") {
                noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
                noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
                noiseFilter.setValue(0.4, forKey: "inputSharpness")
                if let noiseReduced = noiseFilter.outputImage {
                    outputImage = noiseReduced
                }
            }
            
        case .glitch:
            if let filter = filterType.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
            
        case .neon:
            if let filter = filterType.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.8, green: 0.0, blue: 1.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let mono = monoFilter.outputImage {
                    outputImage = mono
                }
            }
            
        default:
            if let filter = filterType.coreImageFilter {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciImage
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func applyFilter(to image: CIImage, filterType: CameraFilterType) -> CIImage {
        guard filterType != .original else { return image }
        
        var outputImage = image
        
        switch filterType {
        case .thermal:
            let gradientColors = [
                UIColor.blue.cgColor,
                UIColor.green.cgColor,
                UIColor.yellow.cgColor,
                UIColor.red.cgColor
            ]
            
            let gradientLocations: [CGFloat] = [0.0, 0.15, 0.25, 0.35, 1.0]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: gradientColors as CFArray,
                                      locations: gradientLocations)
            
            let gradientSize = CGSize(width: 256, height: 1)
            UIGraphicsBeginImageContext(gradientSize)
            let context = UIGraphicsGetCurrentContext()
            context?.drawLinearGradient(
                gradient!,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: gradientSize.width, y: 0),
                options: []
            )
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let gradientCIImage = CIImage(image: gradientImage!) else {
                return CIImage()
            }
            
            if let colorMap = CIFilter(name: "CIColorMap") {
                colorMap.setValue(image, forKey: kCIInputImageKey)
                colorMap.setValue(gradientCIImage, forKey: "inputGradientImage")
                if let colorMap = colorMap.outputImage {
                    outputImage = colorMap
                }
            }
            
        case .night:
            if let contrastFilter = CIFilter(name: "CIColorControls") {
                contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
                contrastFilter.setValue(2.0, forKey: kCIInputContrastKey)
                if let result = contrastFilter.outputImage {
                    outputImage = result
                }
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.0, green: 1.0, blue: 0.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let result = monoFilter.outputImage {
                    outputImage = result
                }
            }
            
            if let noiseFilter = CIFilter(name: "CINoiseReduction") {
                noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
                noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
                noiseFilter.setValue(0.4, forKey: "inputSharpness")
                if let result = noiseFilter.outputImage {
                    outputImage = result
                }
            }
            
        case .glitch:
            if let filter = filterType.coreImageFilter {
                filter.setValue(image, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? image
            }
            
        case .neon:
            if let filter = filterType.coreImageFilter {
                filter.setValue(image, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? image
            }
            
            if let monoFilter = CIFilter(name: "CIColorMonochrome") {
                monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
                monoFilter.setValue(CIColor(red: 0.8, green: 0.0, blue: 1.0), forKey: kCIInputColorKey)
                monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let result = monoFilter.outputImage {
                    outputImage = result
                }
            }
            
        default:
            if let filter = filterType.coreImageFilter {
                filter.setValue(image, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? image
            }
        }
        
        return outputImage
    }
}
