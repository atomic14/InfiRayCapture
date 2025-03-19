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

enum IrProError: String, Error {
    case noDevicesFound = "No IR camera devices found."
    case failedToCreateDeviceInput = "Failed to create device input."
    case failedToAddToSession = "Could not add to capture session."
    case failedToAddOutput = "Failed to set video output."
}

class Camera: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Published properties for UI updates
    @Published var resultImage: CGImage? = nil
    @Published var minTemperature: Float = 0
    @Published var maxTemperature: Float = 0
    @Published var centerTemperature: Float = 0.0
    @Published var averageTemperature: Float = 0
    @Published var currentColorMap: ColorMap {
        didSet {
            UserDefaults.standard.set(colorMaps.firstIndex(of: currentColorMap)!, forKey: "currentColorMap")
        }
    }
    @Published var currentOrientation: OrientationOption {
        didSet {
            UserDefaults.standard.set(orientationOptions.firstIndex(of: currentOrientation)!, forKey: "currentRotation")
        }
    }
    @Published var isRunning = false
    @Published var isRecording = false
    @Published var histogram: [HistogramPoint] = []
    
    // Private components
    private let ciContext = CIContext()
    private let captureSession = AVCaptureSession()
    private let temperatureProcessor = TemperatureProcessor()
    private let videoRecorder = VideoRecorder()
    private var isProcessing = false
    
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
    
    func start() throws -> Bool {
        if isRunning {
            return true
        }
        
        // Find our USB Camera device
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        let devices = discoverySession.devices
        guard let videoCaptureDevice = devices.filter({ $0.localizedName.contains("USB Camera") }).first else {
            throw IrProError.noDevicesFound
        }
        
        // Set up the session
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            throw IrProError.failedToCreateDeviceInput
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            throw IrProError.failedToAddToSession
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.setSampleBufferDelegate(self, queue: .main)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
        } else {
            throw IrProError.failedToAddOutput
        }
        
        captureSession.startRunning()
        isRunning = true
        print("Camera started!")
        return true
    }
    
    func stop() {
        if isRunning {
            captureSession.stopRunning()
            isRunning = false
        }
    }
    
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
    
    func startRecording(outputURL: URL) -> Bool {
        let (width, height) = currentOrientation.translateX(CGFloat(WIDTH), y: CGFloat(HEIGHT))
        isRecording = videoRecorder.startRecording(outputURL: outputURL, width: width, height: height)
        return isRecording
    }
    
    func stopRecording() {
        isRecording = false
        videoRecorder.stopRecording {
            print("Recording finished")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
