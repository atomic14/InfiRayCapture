import Foundation
import AVFoundation
import CoreImage
import CoreGraphics

/// A class that handles video recording functionality for thermal camera output.
///
/// VideoRecorder manages the process of:
/// - Creating and configuring video recording sessions
/// - Converting and writing individual frames to video
/// - Managing video recording state and resources
/// - Handling video file output
class VideoRecorder {
    /// The AVAssetWriter instance responsible for writing video data to disk
    private var assetWriter: AVAssetWriter?
    /// The input interface for writing video frames
    private var videoInput: AVAssetWriterInput?
    /// Adapter for converting CGImage frames to the video pixel format
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    /// Timestamp of the last recorded frame for timing calculations
    private var lastFrameTime: Double = 0.0
    
    /// Starts a new video recording session.
    ///
    /// This method:
    /// 1. Creates a new video file at the specified location
    /// 2. Configures video encoding settings (H.264, bitrate, etc.)
    /// 3. Sets up the necessary AVFoundation components
    /// 4. Begins the recording session
    ///
    /// - Parameters:
    ///   - outputURL: The file URL where the video will be saved
    ///   - width: The width of the video in pixels
    ///   - height: The height of the video in pixels
    /// - Returns: Boolean indicating whether recording started successfully
    func startRecording(outputURL: URL, width: CGFloat, height: CGFloat) -> Bool {
        print("Start recording video to \(outputURL.path)")
        print("Recording size is \(width) x \(height)")
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Create asset writer
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            print("Failed to create asset writer: \(error)")
            return false
        }
        
        guard let assetWriter = assetWriter else {
            print("Asset writer is nil")
            return false
        }
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        // Create and configure video input
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        guard let videoInput = videoInput else {
            print("Could not create videoInput")
            return false
        }

        // We'll be sending frames as they arrive from the capture device
        videoInput.expectsMediaDataInRealTime = true
        
        // Create pixel buffer adaptor
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(width),
                kCVPixelBufferHeightKey as String: Int(height)
            ]
        )
        if pixelBufferAdaptor == nil {
            print("Failed to create pixel buffer adaptor")
            return false
        }
        
        // add the video input
        guard assetWriter.canAdd(videoInput) else {
            print("Can't add input")
            return false
        }
        assetWriter.add(videoInput)
        // and start recording
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        // use this as a starting point for subsequent frames
        lastFrameTime = Date().timeIntervalSince1970
        print("Started recording")
        return true
    }
    
    /// Records a single frame to the video file.
    ///
    /// This method handles:
    /// 1. Converting the CGImage to the appropriate pixel buffer format
    /// 2. Timing calculations for frame presentation
    /// 3. Writing the frame to the video file
    ///
    /// - Parameter image: The CGImage frame to record
    /// - Returns: Boolean indicating whether the frame was recorded successfully
    func recordFrame(_ image: CGImage) -> Bool {
        guard let videoInput = videoInput else {
            print("videoInput is nil!")
            return false
        }
        
        guard videoInput.isReadyForMoreMediaData else {
            print("Not ready for more media data")
            return false
        }

        guard let pixelBufferAdaptor = pixelBufferAdaptor else {
            print("No pixel buffer adaptor")
            return false
        }

        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            print("Could not get pixelBufferPool")
            return false
        }
        
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            pixelBufferPool,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            print("Could not create pixel buffer")
            return false
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            print("Could not create CGContext")
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return false
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let timeNow = Date().timeIntervalSince1970
        let elapsed = timeNow - lastFrameTime

        guard pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMTime(seconds: elapsed, preferredTimescale: 60)) else {
            print("could not append pixel buffer")
            return false
        }
        return true
    }
    
    /// Stops the current recording session and finalizes the video file.
    ///
    /// This method:
    /// 1. Marks the recording as finished
    /// 2. Finalizes the video file
    /// 3. Cleans up recording resources
    /// 4. Calls the completion handler when finished
    ///
    /// - Parameter completion: Closure to be called when recording has finished
    func stopRecording(completion: @escaping () -> Void) {
        print("Stopping recording...")
        guard let videoInput = videoInput else {
            print("No video input!")
            completion()
            return
        }
        videoInput.markAsFinished()
        
        guard let assetWriter = assetWriter else {
            print("No asset writer!")
            completion()
            return
        }
        
        assetWriter.finishWriting {
            self.assetWriter = nil
            self.videoInput = nil
            self.pixelBufferAdaptor = nil
            completion()
        }
    }
} 
