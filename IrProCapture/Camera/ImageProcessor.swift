import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import Accelerate

extension CIImage {
    // To be honest - not completely sure what's going on here - but trial and error has produced this code...
    func getTextOrientation(_ imageOrientation: CGImagePropertyOrientation) -> CGImagePropertyOrientation {
        // Handle rotation
        switch(imageOrientation) {
        case .left:
            return .right
        case .right:
            return .left
        case .leftMirrored:
            return .right
        case .rightMirrored:
            return .left
        default:
            return imageOrientation
        }
    }
    
    func overlayTemperature(temperature: Float, xPos: CGFloat, yPos: CGFloat, orientation: CGImagePropertyOrientation, color: NSColor = .white) -> CIImage? {
        // Create text filter for the actual text
        let textFilter = CIFilter.attributedTextImageGenerator()
        let attributedText = NSAttributedString(
            string: String(format: "%.1f°C", temperature),
            attributes: [.foregroundColor: color]
        )
        textFilter.scaleFactor = 2
        textFilter.text = attributedText
        
        // Create dark background for better visibility
        let blackTextFilter = CIFilter.attributedTextImageGenerator()
        let blackAttributedText = NSAttributedString(
            string: String(format: "%.1f°C", temperature),
            attributes: [.foregroundColor: NSColor.black]
        )
        blackTextFilter.scaleFactor = 2
        blackTextFilter.text = blackAttributedText
        
        // Apply blur to the background
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.radius = 0.5
        blurFilter.inputImage = blackTextFilter.outputImage
        
        // Composite text over background
        guard var textImage = textFilter.outputImage?.composited(over: blurFilter.outputImage!).oriented(getTextOrientation(orientation)) else {
            return nil
        }
        
        // handle text appearing upside down
        if orientation == .leftMirrored || orientation == .rightMirrored {
            textImage = textImage.transformed(by: CGAffineTransform(scaleX: -1.0, y: 1.0))
        }
        
        // Position the text
        let width = self.extent.width
        let height = self.extent.height
        let textImageTranslated = textImage.transformed(
            by: CGAffineTransform(
                translationX: width * xPos - textImage.extent.width / 2,
                y: (height * (1 - yPos) - textImage.extent.height / 2)
            )
        ).cropped(to: self.extent)
        
        // Composite text over main image
        let compositeFilter = CIFilter.sourceOverCompositing()
        compositeFilter.inputImage = textImageTranslated
        compositeFilter.backgroundImage = self
        return compositeFilter.outputImage
    }
    
    static func fromTemperatures(temperatures: [Float], minTemp: Float, maxTemp: Float, width: Int, height: Int, scale: Float, colorMap: ColorMap) -> CIImage? {
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let range = max(maxTemp - minTemp, 1.0)
        let scaledTemperatures = vDSP.multiply(255.0 / range, vDSP.add(-minTemp, temperatures))
        var dstIndex = 0
        for index in 0..<width*height {
            let temp = UInt8(scaledTemperatures[index])
            pixelData[dstIndex] = temp
            pixelData[dstIndex + 1] = temp
            pixelData[dstIndex + 2] = temp
            pixelData[dstIndex + 3] = 255
            dstIndex += 4
        }
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let data = Data(bytes: pixelData, count: pixelData.count)
        let greyScale = CIImage(bitmapData: data, bytesPerRow: bytesPerRow, size: CGSize(width: width, height: height), format: .RGBA8, colorSpace: colorSpace)
        
        // Apply color map
        colorMap.filter.inputImage = greyScale
        
        // Scale the image
        let scaleFilter = CIFilter.lanczosScaleTransform()
        scaleFilter.scale = scale
        scaleFilter.inputImage = colorMap.filter.outputImage
        
        return scaleFilter.outputImage
    }
        
    func toCGImage(ciContext: CIContext, orientation: CGImagePropertyOrientation) -> CGImage? {
        let orientedImage = self.oriented(orientation)
        return ciContext.createCGImage(
            orientedImage,
            from: CGRect(x: 0, y: 0, width: orientedImage.extent.width, height: orientedImage.extent.height)
        )
    }
}

