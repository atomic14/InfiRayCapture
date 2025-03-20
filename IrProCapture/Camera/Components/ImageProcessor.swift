import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import Accelerate

/// Extension to CIImage providing thermal image processing capabilities.
extension CIImage {
    /// Determines the correct text orientation based on the image orientation.
    ///
    /// This method handles various image rotation cases to ensure text overlays
    /// are correctly oriented relative to the image orientation.
    ///
    /// - Parameter imageOrientation: The orientation of the base image
    /// - Returns: The adjusted orientation for text overlays
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
    
    /// Overlays a temperature reading on the image at a specified position.
    ///
    /// This method creates a temperature overlay with:
    /// - Temperature value with degree symbol
    /// - Dark background for better visibility
    /// - Gaussian blur for smooth background
    /// - Proper positioning and orientation
    ///
    /// - Parameters:
    ///   - temperature: The temperature value to display
    ///   - xPos: Normalized X position (0-1) for the overlay
    ///   - yPos: Normalized Y position (0-1) for the overlay
    ///   - orientation: The desired orientation of the text
    ///   - color: The color of the temperature text (default: white)
    /// - Returns: A new CIImage with the temperature overlay, or nil if the operation fails
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
    
    /// Creates a colorized thermal image from raw temperature data.
    ///
    /// This method performs the following steps:
    /// 1. Converts temperature values to grayscale pixels
    /// 2. Creates a grayscale image from the pixel data
    /// 3. Applies a color map for thermal visualization
    /// 4. Scales the image to the desired size
    ///
    /// - Parameters:
    ///   - temperatures: Array of raw temperature values
    ///   - minTemp: Minimum temperature in the data for scaling
    ///   - maxTemp: Maximum temperature in the data for scaling
    ///   - width: Width of the temperature data in pixels
    ///   - height: Height of the temperature data in pixels
    ///   - scale: Scale factor to apply to the final image
    ///   - colorMap: The color map to use for thermal visualization
    /// - Returns: A new CIImage with the processed thermal data, or nil if the operation fails
    static func fromTemperatures(temperatures: [Float], minTemp: Float, maxTemp: Float, width: Int, height: Int, scale: Float, colorMap: ColorMap) -> CIImage? {
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let range = max(maxTemp - minTemp, 1.0)
        let scaledTemperatures = vDSP.multiply(255.0 / range, vDSP.add(-minTemp, temperatures))
        for index in 0..<width*height {
            pixelData[index] = UInt8(scaledTemperatures[index])
        }
        let bytesPerRow = width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let data = Data(bytes: pixelData, count: pixelData.count)
        let greyScale = CIImage(bitmapData: data, bytesPerRow: bytesPerRow, size: CGSize(width: width, height: height), format: .L8, colorSpace: colorSpace)
        
        // Apply color map
        colorMap.filter.inputImage = greyScale
        
        // Scale the image
        let scaleFilter = CIFilter.lanczosScaleTransform()
        scaleFilter.scale = scale
        scaleFilter.inputImage = colorMap.filter.outputImage
        
        return scaleFilter.outputImage
    }
        
    /// Converts a CIImage to a CGImage with the specified orientation.
    ///
    /// - Parameters:
    ///   - ciContext: The Core Image context to use for the conversion
    ///   - orientation: The desired orientation for the output image
    /// - Returns: A new CGImage with the specified orientation, or nil if the conversion fails
    func toCGImage(ciContext: CIContext, orientation: CGImagePropertyOrientation) -> CGImage? {
        let orientedImage = self.oriented(orientation)
        return ciContext.createCGImage(
            orientedImage,
            from: CGRect(x: 0, y: 0, width: orientedImage.extent.width, height: orientedImage.extent.height)
        )
    }
}

