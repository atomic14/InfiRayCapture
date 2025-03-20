//
//  Environment.swift
//  IrProCapture
//
//  Created by Chris Greening on 17/3/25.
//

import Foundation
import AppKit
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

/// A camera controller class that manages thermal imaging capture, processing, and recording.
/// 
/// The `Camera` class serves as the main controller for thermal imaging operations, handling:
/// - Real-time thermal image capture and processing
/// - Temperature data analysis and visualization
/// - Image and video recording capabilities
/// - Color map and orientation management
///
/// This class implements the `ObservableObject` protocol for SwiftUI integration and
/// `CaptureDelegate` for handling camera capture events.
class Camera: NSObject, ObservableObject, CaptureDelegate {
    // MARK: - Published Properties
    
    /// The processed thermal image ready for display
    @Published var resultImage: CGImage? = nil
    
    /// The minimum temperature detected in the current frame
    @Published var minTemperature: Float = 0
    
    /// The maximum temperature detected in the current frame
    @Published var maxTemperature: Float = 0
    
    /// The temperature at the center of the frame
    @Published var centerTemperature: Float = 0.0
    
    /// The average temperature across the entire frame
    @Published var averageTemperature: Float = 0
    
    /// The currently selected color map for thermal visualization
    @Published var currentColorMap: ColorMap {
        didSet {
            UserDefaults.standard.set(colorMaps.firstIndex(of: currentColorMap)!, forKey: "currentColorMap")
        }
    }
    
    /// The current orientation setting for the thermal image
    @Published var currentOrientation: OrientationOption {
        didSet {
            UserDefaults.standard.set(orientationOptions.firstIndex(of: currentOrientation)!, forKey: "currentRotation")
        }
    }
    
    /// Indicates whether the camera is currently running
    @Published var isRunning = false
    
    /// Indicates whether video recording is in progress
    @Published var isRecording = false
    
    /// Temperature distribution data for histogram visualization
    @Published var histogram: [HistogramPoint] = []
    
    // Private components
    private let ciContext = CIContext()
    private let temperatureProcessor = TemperatureProcessor()
    private let videoRecorder = VideoRecorder()
    private var isProcessing = false
    private var capture: Capture?
    
    override init() {
        // Initialise any user defaults
        let colorMapIndex = UserDefaults.standard.integer(forKey: "currentColorMap")
        if colorMapIndex >= 0 && colorMapIndex < colorMaps.count {
            self.currentColorMap = colorMaps[colorMapIndex]
        } else {
            self.currentColorMap = colorMaps[0]
            UserDefaults.standard.set(0, forKey: "currentColorMap")
        }
        let currentOrientationIndex = UserDefaults.standard.integer(forKey: "currentOrientation")
        if currentOrientationIndex >= 0 || currentOrientationIndex < orientationOptions.count {
            self.currentOrientation = orientationOptions[UserDefaults.standard.integer(forKey: "currentOrientation")]
        } else {
            self.currentOrientation = orientationOptions[7]
            UserDefaults.standard.set(7, forKey: "currentOrientation")
        }
        super.init()
    }
    
    /// Starts the thermal camera capture session.
    /// 
    /// - Returns: A boolean indicating whether the camera started successfully.
    /// - Throws: Camera initialization or permission errors.
    func start() throws -> Bool {
        if isRunning {
            return true
        }
        
        capture = Capture(delegate: self)
        isRunning = try capture?.start() ?? false
        return isRunning
    }
    
    /// Stops the thermal camera capture session.
    func stop() {
        capture?.stop()
        isRunning = false
    }
    
    /// Saves the current thermal image to disk as a PNG file.
    /// 
    /// - Parameter outputURL: The URL where the image should be saved.
    /// - Returns: A boolean indicating whether the save operation was successful.
    func saveImage(outputURL: URL) -> Bool {
        guard let resultImage = resultImage else {
            print("No image to save")
            return false
        }
        
        // If the file already exists we need to delete it
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Create an image destination for PNG format
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            print("Failed to create image destination")
            return false
        }
        
        // Add the CGImage to the destination
        CGImageDestinationAddImage(destination, resultImage, nil)
        
        // Finalize the image writing
        if CGImageDestinationFinalize(destination) {
            print("Image saved successfully!")
            return true
        } else {
            print("Failed to save image")
            return false
        }
    }
    
    /// Begins recording thermal video to disk.
    /// 
    /// - Parameter outputURL: The URL where the video should be saved.
    /// - Returns: A boolean indicating whether recording started successfully.
    func startRecording(outputURL: URL) -> Bool {
        let (width, height) = currentOrientation.translateX(CGFloat(WIDTH), y: CGFloat(HEIGHT))
        isRecording = videoRecorder.startRecording(outputURL: outputURL, width: width, height: height)
        return isRecording
    }
    
    /// Stops the current video recording session.
    func stopRecording() {
        isRecording = false
        videoRecorder.stopRecording {
            print("Recording finished")
        }
    }
    
    // MARK: - CaptureDelegate
    
    /// Processes new frames from the thermal camera.
    /// 
    /// This method handles:
    /// - Temperature data extraction
    /// - Image processing and colorization
    /// - Video recording
    /// - UI updates
    /// 
    /// - Parameters:
    ///   - capture: The capture instance that produced the frame
    ///   - sampleBuffer: The raw frame data buffer
    func capture(_ capture: Capture, didOutput sampleBuffer: CMSampleBuffer) {
        if isProcessing {
            return
        }
        isProcessing = true
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)?.assumingMemoryBound(to: UInt16.self) else {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            isProcessing = false
            return
        }
        
        // Process temperatures
        let tempResult = temperatureProcessor.getTemperatures(from: baseAddress, bytesPerRow: bytesPerRow)
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        // Convert temperatures to a color mapped image
        guard let processedImage = CIImage.fromTemperatures(
                temperatures: tempResult.temperatures,
                minTemp: tempResult.min,
                maxTemp: tempResult.max,
                width: 256,
                height: 192,
                scale: SCALE,
                colorMap: currentColorMap
            )?.overlayTemperature(
                temperature: tempResult.center,
                xPos: 0.5,
                yPos: 0.5,
                orientation: currentOrientation.orientation
            )?.overlayTemperature(
                temperature: tempResult.max,
                xPos: CGFloat(tempResult.maxX),
                yPos: CGFloat(tempResult.maxY),
                orientation: currentOrientation.orientation,
                color: .red
            )?.toCGImage(
                ciContext: ciContext,
                orientation: currentOrientation.orientation
            )
        else {
            isProcessing = false
            return
        }

        // Handle video recording
        if isRecording {
            _ = videoRecorder.recordFrame(processedImage)
        }
        
        // Update UI
        Task { @MainActor in
            self.histogram = tempResult.histogram
            self.resultImage = processedImage
            self.minTemperature = tempResult.min
            self.maxTemperature = tempResult.max
            self.averageTemperature = tempResult.average
            self.centerTemperature = tempResult.center
            self.isProcessing = false
        }
    }
}
