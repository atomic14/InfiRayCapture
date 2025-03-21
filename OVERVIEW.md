# IrProCapture - Thermal Imaging Application

IrProCapture is a macOS application for capturing, analyzing, and recording thermal imaging data from InfiRay thermal cameras. This document provides an overview of the system architecture to help developers understand how the components fit together and where to look when adding new features.

## System Architecture

The application follows a Model-View-Controller (MVC) pattern:

- **Model**: The `Camera` class serves as the main model, managing capture, processing, and state
- **View**: SwiftUI views in `ContentView.swift` display the thermal data and controls
- **Controller**: The `IrProCaptureApp.swift` initializes the application and sets up the UI structure

## Core Components

### Camera (Model)

`Camera.swift` is the central component that:
- Manages the thermal camera state and configuration
- Processes temperature data
- Handles image colorization and visualization
- Manages recording and capture functionality

The Camera class implements:
- `ObservableObject` for SwiftUI integration
- `CaptureDelegate` for handling camera capture events

### Capture System

The capture stack consists of several specialized components:

1. **Capture** (`Capture.swift`)
   - Manages the AVCaptureSession for the USB thermal camera
   - Configures the camera device and capture settings
   - Delivers raw frame data to the Camera model

2. **TemperatureProcessor** (`TemperatureProcessor.swift`)
   - Converts raw sensor data to temperature values
   - Handles frame averaging for noise reduction
   - Computes temperature statistics (min, max, average)
   - Generates histogram data for visualization

3. **ImageProcessor** (`ImageProcessor.swift`, via CIImage extension)
   - Transforms temperature data into visualized thermal images
   - Applies color mapping based on selected color scheme
   - Overlays temperature readings at specific points
   - Handles image orientation and transformations

4. **VideoRecorder** (`VideoRecorder.swift`)
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

The application uses SwiftUI for its user interface:

1. **ContentView** (`ContentView.swift`)
   - Main view displaying the thermal image
   - Shows temperature statistics and histogram
   - Handles user interactions and error states

2. **App Structure** (`IrProCaptureApp.swift`)
   - Sets up the application window and menu commands
   - Configures the command menu for color maps, orientation, and capture functions

## Data Flow

The data flows through the system as follows:

1. The thermal camera produces raw frame data
2. `Capture` receives the frame and passes it to `Camera` via delegate methods
3. `Camera` uses `TemperatureProcessor` to extract temperature values and statistics
4. The processed data is used to generate a colorized image via CIImage extensions
5. The resulting image and statistics are published to update the UI
6. If recording, each processed frame is sent to `VideoRecorder` for encoding

## Adding New Features

### Adding a New Color Map

1. Define a new color map array in `ColorMaps.swift`
2. Add it to the `colorMaps` array
3. The UI will automatically include it in the ColorMap menu

### Supporting a New Camera

1. Update the camera detection in `Capture.swift`
2. Modify the `TemperatureProcessor` to handle the camera's specific data format

### Adding Image Processing Features

1. Extend the CIImage extensions in `ImageProcessor.swift`
2. Incorporate new processing in the `capture(_:didOutput:)` method in `Camera.swift`

### Adding New UI Features

1. Modify `ContentView.swift` for in-view controls
2. Add new commands to `IrProCaptureApp.swift` for menu-based features

## Error Handling

The application uses a custom `IrProError` enum for error conditions, primarily related to camera initialization and capture. Error handling is implemented in the UI layer to show appropriate error messages to the user.

## Performance Considerations

- The application uses Apple's Accelerate framework for efficient processing of temperature data
- Frame averaging can be enabled to reduce noise at the cost of responsiveness
- Video recording is optimized to minimize frame drops during capture

## Dependencies

The application relies on several Apple frameworks:
- AVFoundation for camera capture
- CoreImage for image processing
- Accelerate for optimized vector operations
- AppKit and SwiftUI for the user interface 