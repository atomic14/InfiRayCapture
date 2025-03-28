import Foundation
import CoreGraphics

/// A structure representing a grid of temperature values overlaid on a thermal image.
/// 
/// The TemperatureGrid provides configurable grid density and positioning,
/// allowing temperature values to be displayed at regular intervals across the entire frame.
struct TemperatureGrid {
    /// The 2D array of temperature values at grid intersections
    var temperatures: [[Float]] = []
    
    /// The 2D array of grid point positions (normalized 0-1 coordinates)
    var positions: [[CGPoint]] = []
        
    /// Updates the grid with new temperature data
    /// 
    /// - Parameters:
    ///   - temperatureData: Array of temperature values
    ///   - width: Width of the temperature data array
    ///   - height: Height of the temperature data array
    mutating func updateGrid(with temperatureData: [Float], width: Int, height: Int, density: GridDensity) {
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
