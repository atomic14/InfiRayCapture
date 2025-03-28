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
    private let uiState: UIState
    
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
        
    /// Temperature grid for displaying temperature values in a grid pattern
    @Published var temperatureGrid = TemperatureGrid()

    /// Temperature distribution data for histogram visualization
    @Published var histogram: [HistogramPoint] = []
    
    /// Historical temperature data for trend visualization (last 60 seconds)
    @Published var temperatureHistory: [TemperatureHistoryPoint] = []
    
    // Private components
    private let ciContext = CIContext()
    private let temperatureProcessor = TemperatureProcessor(averagingEnabled: false, maxFrameCount: 0)
    private let videoRecorder = VideoRecorder()
    private let imageCapturer = ImageCapturer()
    private var isProcessing = false
    private var capture: Capture?
        
    init(uiState: UIState)
    {
        self.uiState = uiState
    }
    
    /// Starts the thermal camera capture session.
    /// 
    /// - Returns: A boolean indicating whether the camera started successfully.
    /// - Throws: Camera initialization or permission errors.
    func start() throws -> Bool {
        if uiState.isRunning {
            return true
        }
        capture = Capture(delegate: self)
        uiState.isRunning = try capture?.start() ?? false
        return uiState.isRunning
    }
    
    /// Stops the thermal camera capture session.
    func stop() {
        if uiState.isRunning {
            capture?.stop()
            uiState.isRunning = false
        }
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
        
        return imageCapturer.saveImage(image: resultImage, outputURL: outputURL)
    }
    
    /// Begins recording thermal video to disk.
    /// 
    /// - Parameter outputURL: The URL where the video should be saved.
    /// - Returns: A boolean indicating whether recording started successfully.
    func startRecording(outputURL: URL) -> Bool {
        let (width, height) = uiState.currentOrientation.translateX(CGFloat(WIDTH), y: CGFloat(HEIGHT))
        uiState.isRecording = videoRecorder.startRecording(outputURL: outputURL, width: width, height: height)
        return uiState.isRecording
    }
    
    /// Stops the current video recording session.
    func stopRecording() {
        if uiState.isRecording {
            uiState.isRecording = false
            videoRecorder.stopRecording {
                print("Recording finished")
            }
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
                colorMap: uiState.currentColorMap
            )?.toCGImage(
                ciContext: ciContext,
                orientation: uiState.currentOrientation.orientation
            )?.overlayTemperatures(
                tempResults: tempResult,
                grid: temperatureGrid,
                orientation: uiState.currentOrientation.orientation,
                format: uiState.temperatureFormat,
                showGrid: uiState.showTemperatureGrid
            )
        else {
            isProcessing = false
            return
        }

        // Handle video recording
        if uiState.isRecording {
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
            self.temperatureHistory = tempResult.temperatureHistory
            self.isProcessing = false
        }
        
        // Update temperature grid
        updateTemperatureGrid(tempResult)
    }
    
    /// Updates the temperature grid with new temperature data.
    ///
    /// - Parameter tempResult: The temperature result containing processed data.
    private func updateTemperatureGrid(_ tempResult: TemperatureResult) {
        temperatureGrid.updateGrid(
            with: tempResult.temperatures,
            width: tempResult.width,
            height: tempResult.height,
            density: uiState.temperatureGridDensity
        )
    }
}
