//
//  CaptureToolbar.swift
//  IrProCapture
//
//  Created on 21/5/25.
//

import SwiftUI

struct CaptureToolbar: View {
    @EnvironmentObject var model: Camera
    @State private var alertMessage: String? = nil

    var body: some View {
        HStack(spacing: 20) {
            Spacer()

            // Capture image button
            Button(action: {
                guard let success = try? model.start(),
                      success else {
                    alertMessage = "Failed to start camera."
                    return
                }
            }) {
                Image(systemName: "play.square")
                    .font(.title)
            }
            .disabled(model.isRunning)
            .buttonStyle(.bordered)
            .help("Start Camera")

            
            // Capture image button
            Button(action: {
                captureImage()
            }) {
                Image(systemName: "camera")
                    .font(.title)
            }
            .disabled(!model.isRunning)
            .buttonStyle(.bordered)
            .help("Capture Image")
            
            // Record video button
            Button(action: {
                if model.isRecording {
                    model.stopRecording()
                } else {
                    startRecording()
                }
            }) {
                if (model.isRecording) {
                    Image(systemName: "record.circle")
                        .foregroundColor(model.isRecording ? .red : .primary)
                } else {
                    Image(systemName: "stop.circle")
                        .font(.title)
                }
            }
            .disabled(!model.isRunning)
            .buttonStyle(.bordered)
            .help(model.isRecording ? "Stop Recording" : "Start Recording")
            
            // Rotate left button
            Button(action: {
                rotateToPreviousOrientation()
            }) {
                Image(systemName: "rotate.left")
                    .font(.title)
            }
            .disabled(!model.isRunning)
            .buttonStyle(.bordered)
            .help("Previous Orientation")
            // Rotate right button
            Button(action: {
                rotateToNextOrientation()
            }) {
                Image(systemName: "rotate.right")
                    .font(.title)
            }
            .disabled(!model.isRunning)
            .buttonStyle(.bordered)
            .help("Next Orientation")
            
            Spacer()
        }
        .alert(isPresented: Binding<Bool>(
            get: { alertMessage != nil },
            set: { _ in alertMessage = nil }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Rotates to the next orientation option in the list
    private func rotateToNextOrientation() {
        // Call the Camera model's method to cycle to the next orientation
        model.nextOrientation()
    }
    
    /// Rotates to the previous orientation option in the list
    private func rotateToPreviousOrientation() {
        // Call the Camera model's method to cycle to the previous orientation
        model.previousOrientation()
    }
    
    /// Handles image capture using a save dialog
    private func captureImage() {
        let panel = NSSavePanel()
        panel.nameFieldLabel = "Save image as:"
        panel.nameFieldStringValue = "thermal.png"
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                if !model.saveImage(outputURL: fileUrl) {
                    alertMessage = "Failed to save image"
                }
            }
        }
    }
    
    /// Handles starting video recording using a save dialog
    private func startRecording() {
        let panel = NSSavePanel()
        panel.nameFieldLabel = "Save video as:"
        panel.nameFieldStringValue = "recording.mp4"
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                if !model.startRecording(outputURL: fileUrl) {
                    alertMessage = "Failed to start recording"
                }
            }
        }
    }

}

// Commenting out the preview for now due to dependency issues
#Preview {
    CaptureToolbar()
    .environmentObject(Camera())
} 
