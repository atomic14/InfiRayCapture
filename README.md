# IrProCapture

[![Build](https://github.com/chrisgreening/IrProCapture/actions/workflows/build.yml/badge.svg)](https://github.com/chrisgreening/IrProCapture/actions/workflows/build.yml)

A macOS application for viewing and capturing thermal imagery from the InfiRay P2Pro USB thermal camera.

## Features

- Real-time thermal camera feed display
- Multiple color map options for thermal visualization
- Temperature histogram display
- Image capture functionality
- Video recording capability
- Adjustable camera orientation
- Temperature range display (min/max)

## Requirements

- macOS
- InfiRay P2Pro USB thermal camera
- Xcode 15.0 or later (for development)

## Installation

1. Clone the repository
2. Open `IrProCapture.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Connect your InfiRay P2Pro thermal camera to your Mac
2. Launch IrProCapture
3. Click "Start Camera" to begin viewing the thermal feed
4. Use the menu bar options to:
   - Change color maps for different thermal visualizations
   - Adjust camera orientation
   - Capture still images
   - Record video

### Menu Commands

- **Color Map**: Select different thermal visualization color schemes
- **Orientation**: Adjust the camera orientation (disabled during recording)
- **Capture**:
  - Save Image: Capture a single thermal image
  - Record: Start video recording
  - Stop Recording: End video recording

## Development

The project is built using SwiftUI and follows modern macOS development practices. Key components include:

- `IrProCaptureApp.swift`: Main application entry point and menu configuration
- `ContentView.swift`: Primary user interface
- `Environment.swift`: Core camera and image processing logic
- `ColorMaps.swift`: Thermal visualization color schemes
- `Rotations.swift`: Camera orientation options

## License

This project is licensed under the MIT License. See the LICENSE file for details.