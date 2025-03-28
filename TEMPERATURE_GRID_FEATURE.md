# Temperature Grid Overlay Feature

## Overview
The Temperature Grid Overlay feature will display a configurable grid of temperature values superimposed on the thermal image. This provides users with precise temperature readings at regular intervals across the entire frame, enabling better analysis of thermal patterns and distributions.

## Feature Requirements

1. Display temperature values in a grid pattern overlaid on the thermal image
2. Allow users to configure grid density (e.g., 4×4, 8×8, 16×16)
3. Provide options for temperature display format (°C, °F)
4. Enable toggling the grid visibility on/off
5. Optimize for readability against varying thermal backgrounds

## Implementation Components

### Model Changes

#### Temperature Grid Data Structure
- Create a new `TemperatureGrid` class/struct in `Camera/Components/TemperatureGrid.swift`
- Store temperature values at grid intersections
- Maintain grid density configuration
- Calculate grid positions based on image dimensions

```swift
struct TemperatureGrid {
    var density: GridDensity
    var temperatures: [[Double]] // 2D array of temperature values
    var positions: [[CGPoint]]   // 2D array of grid point positions
    
    enum GridDensity: String, CaseIterable, Identifiable {
        case low = "4×4"
        case medium = "8×8"
        case high = "16×16"
        
        var id: String { self.rawValue }
        var dimensions: (Int, Int) {
            switch self {
                case .low: return (4, 4)
                case .medium: return (8, 8)
                case .high: return (16, 16)
            }
        }
    }
    
    // Methods for updating grid data
    mutating func updateGrid(with temperatureData: TemperatureData, dimensions: CGSize)
}
```

### Processing Changes

#### TemperatureProcessor Updates
- Extend `TemperatureProcessor.swift` to sample temperatures at grid points
- Calculate grid intersection temperature values efficiently
- Add necessary methods to `Camera.swift` for accessing grid data

#### ImageProcessor Updates
- Modify `ImageProcessor.swift` to overlay the temperature grid
- Implement adaptive text coloring for readability against varying backgrounds
- Handle grid drawing with proper scaling and positioning

```swift
// Addition to ImageProcessor.swift
func overlayTemperatureGrid(on image: CIImage, grid: TemperatureGrid, format: TemperatureFormat) -> CIImage {
    // Draw the grid text values on the image
    // Use contrasting colors for text based on underlying thermal values
    // Format temperature according to user preferences
}
```

### UI Changes

#### New Configuration View
- Create `TemperatureGridSettingsView.swift` for grid configuration
- Provide options for density, visibility, and format

#### ContentView Updates
- Update `ContentView.swift` to include the grid overlay when enabled
- Add control for toggling grid visibility

#### Menu Integration
- Add menu items to `IrProCaptureApp.swift` for grid control
- Include options for grid density and toggling visibility

```swift
// Menu commands to add
.commandGroup(after: .windowSize) {
    Menu("Temperature Grid") {
        Toggle("Show Grid", isOn: $camera.showTemperatureGrid)
        
        Menu("Grid Density") {
            ForEach(TemperatureGrid.GridDensity.allCases) { density in
                Button(density.rawValue) {
                    camera.temperatureGridDensity = density
                }
            }
        }
    }
}
```

## Implementation Steps

1. **Create Data Model**
   - Implement the `TemperatureGrid` data structure
   - Add grid properties to the `Camera` class
   - Create user preference handling for grid settings

2. **Processing Logic**
   - Implement temperature sampling at grid intersections
   - Add grid calculation methods to process each frame
   - Build text rendering with adaptive coloring

3. **UI Components**
   - Create grid settings configuration view
   - Update Camera to publish grid data changes
   - Implement grid visibility toggle

4. **Integration**
   - Connect temperature processing to grid updates
   - Ensure grid updates efficiently with each frame
   - Add menu items for grid control

5. **Testing**
   - Test with different camera resolutions
   - Verify grid accuracy against point measurements
   - Check performance impact at different grid densities

## Performance Considerations

1. **Efficient Sampling**
   - Use Accelerate framework for efficient grid value extraction
   - Consider subsampling for higher grid densities to maintain performance

2. **Rendering Optimization**
   - Cache grid position calculations when dimensions don't change
   - Consider rendering the grid as a separate layer that updates less frequently than the thermal image

3. **UI Responsiveness**
   - Ensure grid overlay doesn't impact frame rate
   - Consider reducing update frequency for dense grids

## Future Enhancements

1. **Custom Grid Regions**
   - Allow users to define specific regions for denser grid analysis
   
2. **Grid Data Export**
   - Enable exporting grid temperature values to CSV/Excel

3. **Visual Customization**
   - Allow customization of grid appearance (color, opacity, text size)
   - Implement alternative display formats (e.g., mini heatmap cells instead of text) 