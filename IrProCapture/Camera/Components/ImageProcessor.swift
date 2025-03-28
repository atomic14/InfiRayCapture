import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import Accelerate

/// Extension to CIImage providing thermal image processing capabilities.
extension CIImage {
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

extension CGImage {
    func mapCoords(x: CGFloat, y: CGFloat, orientation: CGImagePropertyOrientation) -> (CGFloat, CGFloat) {
        switch orientation {
        case .rightMirrored:
            return (1 - y, x)
        case .up:
            return (x, 1 - y)
        case .upMirrored:
            return (1 - x, 1 - y)
        case .down:
            return (1 - x, y)
        case .downMirrored:
            return (x, y)
        case .left:
            return (y, x)
        case .leftMirrored:
            return (y, 1 - x)
        case .right:
            return (1 - y, 1 - x)
        }
    }
    
    func drawText(
        text: NSAttributedString,
        in context: CGContext,
        x: CGFloat,
        y: CGFloat,
        orientation: CGImagePropertyOrientation
    ) {
        // Calculate text size
        let textSize = text.size()
        
        let (oX, oY) = mapCoords(x: x, y: y, orientation: orientation)

        // Calculate position in image coordinates
        let xPos = oX * CGFloat(self.width) - textSize.width / 2
        let yPos = oY * CGFloat(self.height) - textSize.height / 2
        
        
        // Draw text with shadow for better visibility
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 0), blur: 2, color: NSColor.black.cgColor)
        let line = CTLineCreateWithAttributedString(text)
        context.textPosition = CGPoint(x: xPos, y: yPos)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    func overlayTemperatures(
        tempResults: TemperatureResult,
        grid: TemperatureGrid,
        orientation: CGImagePropertyOrientation
    ) -> CGImage? {
        // Create a bitmap context with the same dimensions as the input image
        let width = self.width
        let height = self.height
        let bytesPerRow = width * 4
        var bitmapData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &bitmapData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }
        
        // Draw the original image
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Configure text attributes
        let fontSize: CGFloat = 12
        let font = NSFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let whiteTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.white
        ]
        let redTextAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.red
        ]

        if grid.isVisible {
            // Draw temperature values at grid points
            for row in 0..<grid.temperatures.count {
                for col in 0..<grid.temperatures[row].count {
                    let temperature = grid.temperatures[row][col]
                    let position = grid.positions[row][col]
                    
                    // Skip if temperature is invalid
                    if temperature.isNaN || temperature < -50 {
                        continue
                    }
                    
                    // Format temperature string
                    let text = grid.format.format(temperature)
                    let attributedText = NSAttributedString(string: text, attributes: whiteTextAttributes)
                    drawText(text: attributedText, in: context, x: position.x, y: position.y, orientation: orientation)
                }
            }
        } else {
            let centerText = grid.format.format(tempResults.center)
            let attributedCenterText = NSAttributedString(string: centerText, attributes: whiteTextAttributes)
            drawText(
                text: attributedCenterText,
                in: context,
                x: 0.5,
                y: 0.5,
                orientation: orientation
            )
            let maxText = grid.format.format(tempResults.max)
            let attributedMaxText = NSAttributedString(string: maxText, attributes: redTextAttributes)
            drawText(
                text: attributedMaxText,
                in: context,
                x: CGFloat(tempResults.maxX),
                y: CGFloat(tempResults.maxY),
                orientation: orientation
            )
        }
        
        // Create and return the new image
        let result = context.makeImage()
        return result
    }
}

