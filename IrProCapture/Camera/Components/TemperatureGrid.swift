import Foundation
import CoreGraphics

/// A structure representing a grid of temperature values overlaid on a thermal image.
/// 
/// The TemperatureGrid provides configurable grid density and positioning,
/// allowing temperature values to be displayed at regular intervals across the entire frame.
struct TemperatureGrid {
    /// The density of the temperature grid
    var density: GridDensity
    
    /// The 2D array of temperature values at grid intersections
    var temperatures: [[Float]]
    
    /// The 2D array of grid point positions (normalized 0-1 coordinates)
    var positions: [[CGPoint]]
    
    /// Indicates whether the grid should be visible
    var isVisible: Bool
    
    /// The temperature display format
    var format: TemperatureFormat
    
    /// Default initializer with empty data
    init(density: GridDensity = .medium, isVisible: Bool = false, format: TemperatureFormat = .celsius) {
        self.density = density
        self.isVisible = isVisible
        self.format = format
        self.temperatures = Array(repeating: Array(repeating: 0.0, count: density.dimensions.1), count: density.dimensions.0)
        self.positions = Array(repeating: Array(repeating: CGPoint.zero, count: density.dimensions.1), count: density.dimensions.0)
    }
    
    /// Updates the grid with new temperature data
    /// 
    /// - Parameters:
    ///   - temperatureData: Array of temperature values
    ///   - width: Width of the temperature data array
    ///   - height: Height of the temperature data array
    mutating func updateGrid(with temperatureData: [Float], width: Int, height: Int) {
        let rows = density.dimensions.0 - 1
        let cols = density.dimensions.1 - 1
        
        // Reset arrays with the correct sizes
        temperatures = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
        positions = Array(repeating: Array(repeating: CGPoint.zero, count: cols), count: rows)
        
        // Calculate step sizes
        let stepX = CGFloat(width - 1) / CGFloat(cols - 1)
        let stepY = CGFloat(height - 1) / CGFloat(rows - 1)
        
        // Fill in temperature values and positions
        for row in 0..<rows {
            for col in 0..<cols {
                let x = Int(round(stepX * CGFloat(col) + stepX/2))
                let y = Int(round(stepY * CGFloat(row) + stepY/2))
                
                // Get temperature at this position
                let index = y * width + x
                if index < temperatureData.count {
                    temperatures[row][col] = temperatureData[index]
                }
                
                // Calculate normalized position (0-1)
                positions[row][col] = CGPoint(
                    x: CGFloat(x) / CGFloat(width),
                    y: CGFloat(y) / CGFloat(height)
                )
            }
        }
    }
}

/// Enum representing different grid density options
enum GridDensity: String, CaseIterable, Identifiable {
    case low = "4×4"
    case medium = "8×8"
    case high = "16×16"
    
    var id: String { self.rawValue }
    
    /// Grid dimensions as (rows, columns)
    var dimensions: (Int, Int) {
        switch self {
            case .low: return (4, 4)
            case .medium: return (8, 8)
            case .high: return (16, 16)
        }
    }
}

/// Enum representing temperature display formats
enum TemperatureFormat: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    var id: String { self.rawValue }
    
    /// Converts a Celsius temperature to the selected format
    func format(_ temperature: Float) -> String {
        switch self {
        case .celsius:
            return String(format: "%.1f°C", temperature)
        case .fahrenheit:
            let fahrenheit = temperature * 9.0/5.0 + 32.0
            return String(format: "%.1f°F", fahrenheit)
        }
    }
} 
