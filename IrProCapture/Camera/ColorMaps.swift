//
//  ColorMaps.swift
//  IrProCapture
//
//  Created by Chris Greening on 17/3/25.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

/// Predefined color mapping for the 'Jet' colormap style
let jetColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.5),  // Dark Blue
    (0.0, 0.0, 1.0),  // Blue
    (0.0, 0.5, 1.0),  // Cyan
    (0.0, 1.0, 1.0),  // Light Cyan
    (0.5, 1.0, 0.0),  // Light Green
    (1.0, 1.0, 0.0),  // Yellow
    (1.0, 0.5, 0.0),  // Orange
    (1.0, 0.0, 0.0)   // Red
]

/// Predefined color mapping for the 'Inferno' colormap style
let infernoColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.13),  // Dark Purple
    (0.23, 0.0, 0.38),  // Deep Red
    (0.54, 0.01, 0.61),  // Dark Orange
    (0.89, 0.38, 0.12),  // Bright Yellow
    (1.0, 0.99, 0.0)     // Bright Yellow
]

/// Predefined color mapping for the 'Viridis' colormap style
let viridisColormap: [(r: Float, g: Float, b: Float)] = [
    (0.13, 0.13, 0.38),  // Dark Purple
    (0.24, 0.29, 0.56),  // Deep Blue
    (0.33, 0.45, 0.73),  // Light Blue
    (0.51, 0.76, 0.55),  // Light Green
    (0.88, 0.98, 0.26)   // Bright Yellow
]

/// Predefined color mapping for the 'Plasma' colormap style
let plasmaColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.13),  // Dark Purple
    (0.26, 0.02, 0.42),  // Deep Pink
    (0.65, 0.16, 0.44),  // Bright Pink
    (1.0, 0.69, 0.0),   // Yellow-Orange
    (1.0, 0.99, 0.0)    // Bright Yellow
]

/// Predefined color mapping for the 'Coolwarm' colormap style
let coolwarmColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.5),    // Dark Blue
    (0.0, 0.0, 1.0),    // Blue
    (0.0, 0.5, 1.0),    // Cyan
    (1.0, 0.5, 0.0),    // Orange
    (1.0, 0.0, 0.0)     // Red
]

/// Predefined color mapping for the 'Magma' colormap style
let magmaColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.13),  // Dark Purple
    (0.25, 0.0, 0.27),  // Purple
    (0.56, 0.0, 0.28),  // Pinkish Red
    (0.89, 0.0, 0.03),  // Yellow-Orange
    (1.0, 0.91, 0.0)    // Light Yellow
]

/// Predefined color mapping for the 'Twilight' colormap style
let twilightColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.5),   // Dark Blue
    (0.0, 0.0, 1.0),   // Blue
    (0.5, 0.0, 1.0),   // Purple
    (1.0, 0.5, 0.0),   // Orange
    (1.0, 1.0, 0.0)    // Yellow
]

/// Predefined color mapping for the 'Autumn' colormap style
let autumnColormap: [(r: Float, g: Float, b: Float)] = [
    (1.0, 1.0, 0.0),   // Yellow
    (1.0, 0.5, 0.0),   // Orange
    (1.0, 0.0, 0.0)    // Red
]

/// Predefined color mapping for the 'Spring' colormap style
let springColormap: [(r: Float, g: Float, b: Float)] = [
    (1.0, 0.0, 1.0),   // Magenta
    (1.0, 1.0, 0.0)    // Yellow
]

/// Predefined color mapping for the 'Winter' colormap style
let winterColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 1.0),   // Blue
    (0.0, 1.0, 0.0)    // Green
]

/// A class that defines a color mapping for thermal image visualization.
///
/// ColorMap provides functionality to:
/// - Define a named set of colors for thermal visualization
/// - Convert grayscale thermal data to color using Core Image filters
/// - Support comparison and hashing for collection storage
class ColorMap: Hashable, Equatable {
    /// Compares two ColorMap instances for equality based on their names.
    static func == (lhs: ColorMap, rhs: ColorMap) -> Bool {
        return lhs.name == rhs.name
    }
    
    /// Generates a hash value for the ColorMap based on its name.
    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
    }
    
    /// The name of the color map (e.g., "Viridis", "Plasma")
    let name: String
    /// The array of RGB color values defining the color mapping
    let colors: [(r: Float, g: Float, b: Float)]
    /// The Core Image filter used to apply the color mapping
    let filter: CIColorCurves
    
    /// Creates a new ColorMap instance.
    ///
    /// - Parameters:
    ///   - name: The name of the color map
    ///   - colors: An array of RGB color values defining the mapping
    init(name: String, colors: [(r: Float, g: Float, b: Float)]) {
        self.name = name
        self.colors = colors
        self.filter = CIFilter.colorCurves()
        self.filter.curvesDomain = CIVector(x: 0, y: 1)
        var colorsData = [Float32].init(repeating: 0, count: colors.count * 3)
        for (i, color) in colors.enumerated() {
            colorsData[i * 3] = color.r
            colorsData[i * 3 + 1] = color.g
            colorsData[i * 3 + 2] = color.b
        }
        self.filter.curvesData = Data(
            bytes: colorsData, count: colors.count * 3 * 4)
        self.filter.colorSpace = CGColorSpaceCreateDeviceRGB()
    }
}

/// The collection of available color maps for thermal visualization
let colorMaps = [
    ColorMap(name: "Viridis", colors: viridisColormap),
    ColorMap(name: "Plasma", colors: plasmaColormap),
    ColorMap(name: "Coolwarm", colors: coolwarmColormap),
    ColorMap(name: "Magma", colors: magmaColormap),
    ColorMap(name: "Twilight", colors: twilightColormap),
    ColorMap(name: "Autumn", colors: autumnColormap),
    ColorMap(name: "Spring", colors: springColormap),
    ColorMap(name: "Winter", colors: winterColormap),
]
