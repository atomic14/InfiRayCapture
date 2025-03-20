import Foundation

/// Errors that can occur during IR camera operations.
///
/// This enum defines various error conditions that may arise when:
/// - Initializing the IR camera
/// - Setting up capture sessions
/// - Configuring video input/output
enum IrProError: String, Error {
    /// No IR camera devices were detected on the system
    case noDevicesFound = "No IR camera devices found."
    /// Failed to create an AVCaptureDeviceInput for the IR camera
    case failedToCreateDeviceInput = "Failed to create device input."
    /// Failed to add the device input to the capture session
    case failedToAddToSession = "Could not add to capture session."
    /// Failed to configure the video output for the capture session
    case failedToAddOutput = "Failed to set video output."
} 