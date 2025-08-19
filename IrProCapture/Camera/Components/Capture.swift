import Foundation
import AVFoundation

/// Protocol for receiving captured frames from the IR camera.
///
/// Implement this protocol to receive and process raw frame data
/// from the thermal camera capture session.
protocol CaptureDelegate: AnyObject {
    /// Called when a new frame is captured from the camera.
    ///
    /// - Parameters:
    ///   - capture: The Capture instance that produced the frame
    ///   - sampleBuffer: The raw frame data buffer
    func capture(_ capture: Capture, didOutput sampleBuffer: CMSampleBuffer)
}

/// A class that manages the IR camera capture session.
///
/// The Capture class handles:
/// - Setting up and configuring the USB camera device
/// - Managing the AVCaptureSession lifecycle
/// - Delivering captured frames to a delegate
class Capture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    /// The underlying AVCaptureSession for camera interaction
    private let captureSession = AVCaptureSession()
    /// The delegate that will receive captured frames
    private weak var delegate: CaptureDelegate?
    /// Indicates whether the capture session is currently running
    private(set) var isRunning = false
    
    /// Creates a new Capture instance.
    ///
    /// - Parameter delegate: The object that will receive captured frames
    init(delegate: CaptureDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    /// Starts the camera capture session.
    ///
    /// This method:
    /// 1. Finds and configures the USB camera device
    /// 2. Sets up the capture session and video output
    /// 3. Begins capturing frames
    ///
    /// - Throws: IrProError if camera setup fails
    /// - Returns: Boolean indicating whether capture started successfully
    func start() throws -> Bool {
        if isRunning {
            return true
        }
        
        // Find our USB Camera device
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        let devices = discoverySession.devices
        // print all the devices to debug log
        print("Found the following cameras:")
        for device in devices {
            print("\t\(device.modelID)")
        }
        
        guard let videoCaptureDevice = devices.filter({ $0.modelID == "UVC Camera VendorID_3034 ProductID_22576" }).first else {
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
    
    /// Stops the camera capture session.
    ///
    /// This method safely stops the capture session and updates the running state.
    func stop() {
        if isRunning {
            captureSession.stopRunning()
            isRunning = false
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    /// Handles new frames from the camera and forwards them to the delegate.
    ///
    /// - Parameters:
    ///   - output: The output that produced the frame
    ///   - sampleBuffer: The captured frame data
    ///   - connection: The connection through which the frame was received
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.capture(self, didOutput: sampleBuffer)
    }
} 
