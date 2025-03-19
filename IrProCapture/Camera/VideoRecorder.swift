import Foundation
import AVFoundation
import CoreImage
import CoreGraphics

class VideoRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var lastFrameTime: Double = 0.0
    
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
