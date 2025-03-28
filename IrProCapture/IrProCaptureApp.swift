//
//  IrProCaptureApp.swift
//  IrProCapture
//
//  Created by Chris Greening on 16/3/25.
//

import SwiftUI

@main
struct IrProCaptureApp: App {
    @StateObject private var uiState: UIState
    private let camera: Camera
    
    init() {
        let uiState = UIState()
        _uiState = StateObject(wrappedValue: uiState)
        self.camera = Camera(uiState: uiState)
    }
    
    var body: some Scene {
        Window("InfiRay Viewer", id: "main") {
            ContentView()
                .environmentObject(uiState)
                .environmentObject(camera)
        }
        .commands {
            CommandMenu("Display") {
                Picker("Color Map", selection: $uiState.currentColorMap) {
                    ForEach(colorMaps, id: \.self) { colorMap in
                        Text(colorMap.name).tag(colorMap)
                    }
                }
                Picker("Temperature Format", selection: $uiState.temperatureFormat) {
                    ForEach(TemperatureFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                Toggle("Show Grid", isOn: $uiState.showTemperatureGrid)
                Picker("Grid Density", selection: $uiState.temperatureGridDensity) {
                    ForEach(GridDensity.allCases) { density in
                        Text(density.rawValue).tag(density)
                    }
                }
                Picker("Orientation", selection: $uiState.currentOrientation) {
                    ForEach(orientationOptions, id: \.self) { orientation in
                        Text(orientation.name).tag(orientation)
                    }
                }
                .disabled(uiState.isRecording)
            }
            
            CommandMenu("Capture") {
                
                Button(action: {
                    let panel = NSSavePanel()
                    panel.nameFieldLabel = "Save image as:"
                    panel.nameFieldStringValue = "thermal.png"
                    panel.canCreateDirectories = true
                    panel.begin { response in
                        if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                            if !camera.saveImage(outputURL: fileUrl) {
                                let alert = NSAlert()
                                alert.alertStyle = .critical
                                alert.messageText = "Failed to save image"
                                alert.runModal()
                            }
                        }
                    }
                }, label: {
                    Text("Save Image")
                }).disabled(!uiState.isRunning)
                
                Button(action: {
                    let panel = NSSavePanel()
                    panel.nameFieldLabel = "Save video as:"
                    panel.nameFieldStringValue = "recording.mp4"
                    panel.canCreateDirectories = true
                    panel.begin { response in
                        if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                            if !camera.startRecording(outputURL: fileUrl) {
                                let alert = NSAlert()
                                alert.alertStyle = .critical
                                alert.messageText = "Failed to start recording"
                                alert.runModal()
                            }
                        }
                    }
                }, label: {
                    Text("Record")
                }).disabled(uiState.isRecording || !uiState.isRunning)
                Button(action: {
                    camera.stopRecording()
                }, label: {
                    Text("Stop Recording")
                }).disabled(!uiState.isRecording)
            }
        }
    }
}
