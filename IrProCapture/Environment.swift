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

let SCALE: Float = 4.0
let WIDTH: Float = 256.0 * SCALE
let HEIGHT: Float = 192.0 * SCALE


extension CIImage {
    func overlayTemperature(temperature: Float, xpos: CGFloat, ypos: CGFloat, rotation: CGImagePropertyOrientation, color: NSColor = .white) -> CIImage {
        
        // the actual text
        let textFilter = CIFilter.attributedTextImageGenerator()
        let attributedText = NSAttributedString(string: String(format: "%.1f°C", temperature), attributes: [
            .foregroundColor: color
        ])
        textFilter.scaleFactor = 2
        textFilter.text = attributedText
        // some dark background for the text to make it more visibl
        let blackTextFilter = CIFilter.attributedTextImageGenerator()
        let blackAttributedText = NSAttributedString(string: String(format: "%.1f°C", temperature), attributes: [
            .foregroundColor: NSColor.black
        ])
        blackTextFilter.scaleFactor = 2
        blackTextFilter.text = blackAttributedText
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.radius = 0.5
        blurFilter.inputImage = blackTextFilter.outputImage
        
        // I have no idea why this works!
        var orientation = rotation
        if orientation == .left {
            orientation = .right
        } else if orientation == .right {
            orientation = .left
        }
        
        // the final text image
        let textImage = textFilter.outputImage!.composited(over: blurFilter.outputImage!).oriented(orientation)

        // move the text into the correct position
        let width = self.extent.width
        let height = self.extent.height
        
        let textImageTranslated = textImage.transformed(
            by: CGAffineTransform(
                translationX: width * xpos - textImage.extent.width / 2,
                y: height * ypos - textImage.extent.height / 2
            )
        ).cropped(to: self.extent)
        
        // finally composite the text on ourselves
        let compositeFilter = CIFilter.sourceOverCompositing()
        compositeFilter.inputImage = textImageTranslated
        compositeFilter.backgroundImage = self
        return compositeFilter.outputImage!
    }
}

enum IrProError: String, Error {
    case noDevicesFound = "No IR camera devices found."
    case failedToCreateDeviceInput = "Failed to create device input."
    case failedToAddToSession = "Could not add to capture session."
    case failedToAddOutput = "Failed to set video output."
}

struct HistogramPoint: Identifiable {
    var id: Float { x }
    
    var x: Float
    var y: Int
}

class Model: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
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
    @Published var currentRotation: RotationOption {
        didSet {
            UserDefaults.standard.set(rotationOptions.firstIndex(of: currentRotation)!, forKey: "currentRotation")
        }
    }
    @Published var isRunning = false
    @Published var isRecording = false
    @Published var histogram: [HistogramPoint] = []

    private let captureSession = AVCaptureSession()
    private let ciContext = CIContext()
    private var tempArray = [Float].init(repeating: 0, count: 256*192)
    private var pixelData = [UInt8].init(repeating: 0, count: 256*192*4)
    private var isProcessing = false
    
    private var assetWriter: AVAssetWriter? = nil
    private var videoInput: AVAssetWriterInput? = nil
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor? = nil
    private var pixelBuffer: CVPixelBuffer? = nil
    private var startRecordingTime = CMTime(seconds: 0, preferredTimescale: 600)
    private var lastFrameTime: Double = 0.0
    
    
    override init() {
        self.currentColorMap = colorMaps[UserDefaults.standard.integer(forKey: "currentColorMap")]
        if UserDefaults.standard.object(forKey: "currentRotation") == nil {
            self.currentRotation = rotationOptions[7]
        } else {
            self.currentRotation = rotationOptions[UserDefaults.standard.integer(forKey: "currentRotation")]
        }
        super.init()
    }
    
    func start() throws -> Bool {
        if isRunning {
            return true
        }
        // find our USB Camera device
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        let devices = discoverySession.devices
        guard let videoCaptureDevice = devices.filter({ $0.localizedName.contains("USB Camera") }).first else {
            throw IrProError.noDevicesFound
        }
        // get the session outputting frames
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
        if !isRunning {
            return false
        }
        guard let resultImage = resultImage else {
            print("No image to save")
            return false
        }
        // if the file already exists we need to delete it
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
        let (width, height) = currentRotation.translateX(CGFloat(WIDTH), y: CGFloat(HEIGHT))
        // if the file already exists we need to delete it
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        if let assetWriter = assetWriter {
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 1000000, // Adjust bitrate
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            
            
            if let videoInput = videoInput {
                videoInput.expectsMediaDataInRealTime = true

                // 3. Create the PixelBufferAdaptor
                pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ])
                
                // 4. Add the video input to the writer
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                } else {
                    // Handle the error
                    print("Unable to add video input")
                    return false
                }
                
                // 5. Start writing
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
            }
            lastFrameTime = Date().timeIntervalSince1970
            isRecording = true
            return true
        }
        return false
    }
    
    func stopRecording() {
        isRecording = false
        assetWriter?.finishWriting {
            print("Finished writing")
        }
    }
    
    func convertTemp<T: BinaryInteger>(raw: T) -> Float {
        return Float(raw)/64.0 - 273.2
    }
    
    func computeHistogram(values: [Float], min: Float, max: Float, bins: Int) -> [HistogramPoint] {
        var histogram = [Int](repeating: 0, count: bins)
        
        // Ensure values are within the specified range
        let range = max - min
        let binWidth = range / Float(bins)
        if (binWidth == 0) {
            return []
        }

        // Iterate through each value
        for value in values {
            // Skip values that are outside the given range
            if value < min || value > max {
                continue
            }
            
            // Find the appropriate bin for the value
            let binIndex = Int((value - min) / binWidth)
            
            // Make sure binIndex is within bounds
            if binIndex >= 0 && binIndex < bins {
                histogram[binIndex] += 1
            }
        }
        return histogram.enumerated().map { (index, element) in
            HistogramPoint(x: Float(index) * binWidth + min, y: element)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isProcessing {
            return
        }
        isProcessing = true
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            CVPixelBufferLockBaseAddress(imageBuffer,.readOnly)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let src_buff = CVPixelBufferGetBaseAddress(imageBuffer)
            
            if let bufferPointer = src_buff?.assumingMemoryBound(to: UInt16.self) {
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                // Iterate over the data and create a UInt16 array
                // we don't care about the top part of the image (256*192) - we only care about the bottom
                var dstIndex = 0
                for row in 192..<height {
                    for column in 0..<width {
                        let index = row * bytesPerRow / MemoryLayout<UInt16>.size + column
                        let value = bufferPointer[index]
                        tempArray[dstIndex] = convertTemp(raw: value.byteSwapped)
                        dstIndex = dstIndex + 1
                    }
                }
            }
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly);
            let minValue = tempArray.min() ?? 0.0
            let maxElement = tempArray.enumerated().max(by: { $0.element < $1.element })
            let maxValue = maxElement?.element ?? 0.0
            let range = max(maxValue - minValue, 1.0)
            let maxX = (maxElement?.offset ?? 0) % 256
            let maxY = 192 - (maxElement?.offset ?? 0) / 256
            let sum = tempArray.reduce(0, { $0 + $1 })
            let aveValue = sum / Float(tempArray.count)
            let centerX = 256 / 2
            let centerY = 192 / 2
            let centerTemp = tempArray[centerX + centerY * 256]
            let histogram = computeHistogram(values: tempArray, min: minValue, max: maxValue, bins: 50)

            for index in 0..<256*192 {
                let temp = tempArray[index]
                let scaled = UInt8(255.0 * (temp - minValue) / range)
                pixelData[index * 4] = scaled
                pixelData[index * 4 + 1] = scaled
                pixelData[index * 4 + 2] = scaled
                pixelData[index * 4 + 3] = 255
            }
            guard let image = convertUInt8ArrayToCIImage(pixelData: pixelData, width: 256, height: 192) else {
                isProcessing = false
                return
            }
            currentColorMap.filter.inputImage = image
            let scaleFilter = CIFilter.lanczosScaleTransform()
            scaleFilter.scale = SCALE
            scaleFilter.inputImage = currentColorMap.filter.outputImage
            
            let outputImage = scaleFilter.outputImage!.overlayTemperature(temperature: centerTemp, xpos: 0.5, ypos: 0.5, rotation: currentRotation.rotation)
                .overlayTemperature(temperature: maxValue, xpos: CGFloat(maxX) / 256.0, ypos: CGFloat(maxY) / 192.0, rotation: currentRotation.rotation, color: .red)
                .oriented(currentRotation.rotation)
            
            guard let processedImage = ciContext.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: outputImage.extent.width, height: outputImage.extent.height)) else {
                isProcessing = false
                return
            }
            
            if isRecording {
                if let videoInput = videoInput {
                    if videoInput.isReadyForMoreMediaData {
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, (pixelBufferAdaptor?.pixelBufferPool)!, &pixelBuffer)

                        if status != kCVReturnSuccess {
                            print("Hmm, no buffer!")
                        }
                        
                        if let pixelBuffer = pixelBuffer {
                            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))

                            let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                                    width: Int(outputImage.extent.width),
                                                    height: Int(outputImage.extent.height),
                                                    bitsPerComponent: 8,
                                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                    space: CGColorSpaceCreateDeviceRGB(),
                                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGImageByteOrderInfo.order32Little.rawValue).rawValue)!
                            
                            context.draw(processedImage, in: CGRect(x: 0, y: 0, width: outputImage.extent.width, height: outputImage.extent.height))

                            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))

                            let timeNow = Date().timeIntervalSince1970
                            let elapsed = timeNow - lastFrameTime
                            pixelBufferAdaptor!.append(pixelBuffer, withPresentationTime: CMTime(seconds: elapsed, preferredTimescale: 60))
                        } else {
                            print("No pixelBuffer :(")
                        }
                    }
                }
            }
            Task {
                @MainActor in do {
                    self.histogram = histogram
                    resultImage = processedImage
                    minTemperature = minValue
                    maxTemperature = maxValue
                    averageTemperature = aveValue
                    centerTemperature = centerTemp
                    isProcessing = false
                }
            }
        }
    }
}
