//
//  CaptureToolbar.swift
//  IrProCapture
//
//  Created on 21/5/25.
//

import SwiftUI

struct CaptureToolbar: View {
    @EnvironmentObject var model: Camera
    @EnvironmentObject var uiState: UIState
    @State private var alertMessage: String? = nil

    var body: some View {
        HStack(spacing: 20) {
            Spacer()

            // Capture image button
            Button(action: {
                do {
                    if !(try model.start()) {
                        alertMessage = "Failed to start camera."
                    }
                } catch let error {
                    alertMessage = error.localizedDescription
                }
            }) {
                Image(systemName: "play.square")
                    .font(.title)
            }
            .disabled(uiState.isRunning)
            .buttonStyle(.bordered)
            .help("Start Camera")

            
            // Capture image button
            Button(action: {
                captureImage()
            }) {
                Image(systemName: "camera")
                    .font(.title)
            }
            .disabled(!uiState.isRunning)
            .buttonStyle(.bordered)
            .help("Capture Image")
            
            // Record video button
            Button(action: {
                if uiState.isRecording {
                    model.stopRecording()
                } else {
                    startRecording()
                }
            }) {
                if (uiState.isRecording) {
                    Image(systemName: "stop.circle")
                        .foregroundColor(uiState.isRecording ? .red : .primary)
                        .font(.title)
                } else {
                    Image(systemName: "record.circle")
                        .font(.title)
                }
            }
            .disabled(!uiState.isRunning)
            .buttonStyle(.bordered)
            .help(uiState.isRecording ? "Stop Recording" : "Start Recording")
            
            // Rotate left button
            Button(action: {
                rotateToPreviousOrientation()
            }) {
                Image(systemName: "rotate.left")
                    .font(.title)
            }
            .disabled(!uiState.isRunning)
            .buttonStyle(.bordered)
            .help("Previous Orientation")
            // Rotate right button
            Button(action: {
                rotateToNextOrientation()
            }) {
                Image(systemName: "rotate.right")
                    .font(.title)
            }
            .disabled(!uiState.isRunning)
            .buttonStyle(.bordered)
            .help("Next Orientation")
            
            Spacer()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            ),
            presenting: alertMessage
        ) { _ in
            // actions
            Button("OK", role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
    }
    
    /// Rotates to the next orientation option in the list
    private func rotateToNextOrientation() {
        // Call the Camera model's method to cycle to the next orientation
        uiState.nextOrientation()
    }
    
    /// Rotates to the previous orientation option in the list
    private func rotateToPreviousOrientation() {
        // Call the Camera model's method to cycle to the previous orientation
        uiState.previousOrientation()
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
    let uiState = UIState()
    CaptureToolbar()
        .environmentObject(Camera(uiState: uiState))
        .environmentObject(uiState)
}
