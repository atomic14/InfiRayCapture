# IrProCapture - Thermal Imaging Application

IrProCapture is a macOS application for capturing, analyzing, and recording thermal imaging data from InfiRay thermal cameras. This document provides an overview of the system architecture to help developers understand how the components fit together and where to look when adding new features.

## System Architecture

The application follows a Model-View-Controller (MVC) pattern:

- **Model**: The `Camera` class serves as the main model, managing capture, processing, and state
- **View**: SwiftUI views in the `Views` directory display the thermal data and controls
- **Controller**: The `IrProCaptureApp.swift` initializes the application and sets up the UI structure

## Core Components

### Camera (Model)

`Camera.swift` is the central component that:
- Manages the thermal camera state and configuration
- Processes temperature data
- Handles image colorization and visualization
- Manages recording and capture functionality
- Tracks temperature history data over time

The Camera class implements:
- `ObservableObject` for SwiftUI integration
- `CaptureDelegate` for handling camera capture events

### Capture System

The capture stack consists of several specialized components within the `Camera/Components` directory:

1. **Capture** (`Capture.swift`)
   - Manages the AVCaptureSession for the USB thermal camera
   - Configures the camera device and capture settings
   - Delivers raw frame data to the Camera model

2. **ImageCapturer** (`ImageCapturer.swift`)
   - Handles the detailed configuration of camera input
   - Manages device discovery and setup

3. **TemperatureProcessor** (`TemperatureProcessor.swift`)
   - Converts raw sensor data to temperature values
   - Handles frame averaging for noise reduction
   - Computes temperature statistics (min, max, average)
   - Generates histogram data for visualization

4. **ImageProcessor** (`ImageProcessor.swift`)
   - Transforms temperature data into visualized thermal images
   - Applies color mapping based on selected color scheme
   - Overlays temperature readings at specific points
   - Handles image orientation and transformations

5. **VideoRecorder** (`VideoRecorder.swift`)
   - Records thermal visualization to video files
   - Manages encoding settings and file output

### Visualization

The visualization system offers rich customization options:

1. **ColorMaps** (`ColorMaps.swift`)
   - Defines various color palettes for thermal visualization
   - Includes standard schemes like Jet, Inferno, Rainbow, etc.
   - Allows for user preference persistence

2. **Rotations** (`Rotations.swift`)
   - Manages image orientation options
   - Handles transformations for different viewing angles

### UI Components

The application uses SwiftUI for its user interface, with components organized in the `Views` directory:

1. **ContentView** (`ContentView.swift`)
   - Main view container that organizes the layout
   - Displays the thermal image and associated visualizations
   - Handles error state presentation

2. **CaptureToolbar** (`Views/CaptureToolbar.swift`)
   - Provides buttons for camera control (start/stop)
   - Handles image capture and video recording
   - Offers image rotation controls
   - Contains logic for file save dialogs

3. **TemperatureHistogramChart** (`Views/TemperatureHistogramChart.swift`)
   - Displays a histogram of temperature distribution
   - Visualizes temperature ranges in the current frame

4. **ColorMapDisplay** (`Views/ColorMapDisplay.swift`)
   - Shows the current color map as a temperature gradient
   - Displays min/max temperature values

5. **TemperatureHistoryChart** (`Views/TemperatureHistoryChart.swift`)
   - Shows a time-series chart of temperature data over the last minute
   - Tracks min, max, average, and center temperatures
   - Updates approximately once per second
   - Provides trend visualization for temperature changes

6. **App Structure** (`IrProCaptureApp.swift`)
   - Sets up the application window and menu commands
   - Configures the command menu for color maps, orientation, and capture functions

## Data Flow

The data flows through the system as follows:

1. The thermal camera produces raw frame data
2. `Capture` receives the frame and passes it to `Camera` via delegate methods
3. `Camera` uses `TemperatureProcessor` to extract temperature values and statistics
4. The processed data is used to generate a colorized image via the `ImageProcessor`
5. The resulting image and statistics are published to update the UI
6. Temperature history is updated approximately once per second for trend visualization
7. If recording, each processed frame is sent to `VideoRecorder` for encoding

## Adding New Features

### Adding a New Color Map

1. Define a new color map array in `ColorMaps.swift`
2. Add it to the `colorMaps` array
3. The UI will automatically include it in the ColorMap menu

### Supporting a New Camera

1. Update the camera detection in `Capture.swift` and `ImageCapturer.swift`
2. Modify the `TemperatureProcessor` to handle the camera's specific data format

### Adding Image Processing Features

1. Extend the image processing in `ImageProcessor.swift`
2. Incorporate new processing in the `capture(_:didOutput:)` method in `Camera.swift`

### Adding New UI Features

1. Create a new SwiftUI view in the `Views` directory
2. Integrate it into `ContentView.swift` or another appropriate parent view
3. Add new commands to `IrProCaptureApp.swift` for menu-based features

## Error Handling

The application uses a custom `IrProError` enum for error conditions, primarily related to camera initialization and capture. Error handling is implemented in the UI layer to show appropriate error messages to the user.

## Performance Considerations

- The application uses Apple's Accelerate framework for efficient processing of temperature data
- Frame averaging can be enabled to reduce noise at the cost of responsiveness
- Video recording is optimized to minimize frame drops during capture
- Temperature history tracking is limited to once per second to minimize performance impact

## Dependencies

The application relies on several Apple frameworks:
- AVFoundation for camera capture
- CoreImage for image processing
- Accelerate for optimized vector operations
- SwiftUI and Charts for the user interface 