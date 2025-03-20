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

/// Predefined color mapping for the 'Turbo' colormap style
let turboColormap: [(r: Float, g: Float, b: Float)] = [
    (0.18995, 0.07176, 0.23217),  // Dark Purple
    (0.19483, 0.28877, 0.75087),  // Deep Blue
    (0.19956, 0.54642, 0.91919),  // Light Blue
    (0.23421, 0.74619, 0.65797),  // Cyan
    (0.49974, 0.91176, 0.23218),  // Green
    (0.83976, 0.84151, 0.11136),  // Yellow
    (0.98072, 0.55989, 0.14996),  // Orange
    (0.90240, 0.19865, 0.16086)   // Red
]

/// Predefined color mapping for the 'Hot' colormap style
let hotColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.0),    // Black
    (0.5, 0.0, 0.0),    // Dark Red
    (1.0, 0.0, 0.0),    // Red
    (1.0, 0.5, 0.0),    // Orange
    (1.0, 1.0, 0.0),    // Yellow
    (1.0, 1.0, 1.0)     // White
]

/// Predefined color mapping for the 'Rainbow' colormap style
let rainbowColormap: [(r: Float, g: Float, b: Float)] = [
    (0.5, 0.0, 1.0),    // Violet
    (0.0, 0.0, 1.0),    // Blue
    (0.0, 1.0, 1.0),    // Cyan
    (0.0, 1.0, 0.0),    // Green
    (1.0, 1.0, 0.0),    // Yellow
    (1.0, 0.0, 0.0)     // Red
]

/// Predefined color mapping for the 'Parula' colormap style
let parulaColormap: [(r: Float, g: Float, b: Float)] = [
    (0.2081, 0.1663, 0.5292),  // Dark Blue
    (0.1986, 0.3743, 0.6029),  // Blue
    (0.1258, 0.5686, 0.6399),  // Cyan
    (0.0343, 0.7244, 0.5914),  // Teal
    (0.3231, 0.8526, 0.4182),  // Green
    (0.7153, 0.9333, 0.1631),  // Yellow
    (0.9932, 0.9062, 0.1439)   // Light Yellow
]

/// Predefined color mapping for the 'HSV' colormap style
let hsvColormap: [(r: Float, g: Float, b: Float)] = [
    (1.0, 0.0, 0.0),    // Red
    (1.0, 1.0, 0.0),    // Yellow
    (0.0, 1.0, 0.0),    // Green
    (0.0, 1.0, 1.0),    // Cyan
    (0.0, 0.0, 1.0),    // Blue
    (1.0, 0.0, 1.0)     // Magenta
]

/// Predefined color mapping for the 'Cubehelix' colormap style
let cubehelixColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.0, 0.0),      // Black
    (0.2196, 0.1039, 0.3637),  // Dark Purple
    (0.3637, 0.3700, 0.5847),  // Purple Blue
    (0.4769, 0.6008, 0.6823),  // Light Blue
    (0.6456, 0.7474, 0.6137),  // Green-Yellow
    (0.8645, 0.7240, 0.5780),  // Light Orange
    (1.0, 1.0, 1.0)       // White
]

/// Predefined color mapping for the 'Cividis' colormap style
let cividisColormap: [(r: Float, g: Float, b: Float)] = [
    (0.0, 0.1259, 0.3022),  // Dark Blue
    (0.1330, 0.3174, 0.4951),  // Medium Blue
    (0.3553, 0.5185, 0.5930),  // Blue-Green
    (0.6866, 0.7863, 0.5775),  // Light Yellow-Green
    (0.9983, 0.9983, 0.6633)   // Light Yellow
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
    ColorMap(name: "Jet", colors: jetColormap),
    ColorMap(name: "Inferno", colors: infernoColormap),
    ColorMap(name: "Turbo", colors: turboColormap),
    ColorMap(name: "Hot", colors: hotColormap),
    ColorMap(name: "Rainbow", colors: rainbowColormap),
    ColorMap(name: "Parula", colors: parulaColormap),
    ColorMap(name: "Viridis", colors: viridisColormap),
    ColorMap(name: "Plasma", colors: plasmaColormap),
    ColorMap(name: "Coolwarm", colors: coolwarmColormap),
    ColorMap(name: "Magma", colors: magmaColormap),
    ColorMap(name: "Twilight", colors: twilightColormap),
    ColorMap(name: "Autumn", colors: autumnColormap),
    ColorMap(name: "Spring", colors: springColormap),
    ColorMap(name: "Winter", colors: winterColormap),
    ColorMap(name: "HSV", colors: hsvColormap),
    ColorMap(name: "Cubehelix", colors: cubehelixColormap),
    ColorMap(name: "Cividis", colors: cividisColormap),
]
