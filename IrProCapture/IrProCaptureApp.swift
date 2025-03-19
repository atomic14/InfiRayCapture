//
//  IrProCaptureApp.swift
//  IrProCapture
//
//  Created by Chris Greening on 16/3/25.
//

import SwiftUI

@main
struct IrProCaptureApp: App {
    @StateObject var model = Camera()
    
    var body: some Scene {
        Window("InfiRay Viewer", id: "main") {
            ContentView().environmentObject(model)
        }
        .commands {
            CommandMenu("Color Map") {
                ForEach(colorMaps, id: \.self) { colorMap in
                    Button(action: {
                        model.currentColorMap = colorMap
                    }) {
                        HStack {
                            Text(colorMap.name)
                            if model.currentColorMap == colorMap {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            CommandMenu("Orientation") {
                ForEach(orientationOptions, id: \.self) { colorMap in
                    Button(action: {
                        model.currentOrientation = colorMap
                    }) {
                        HStack {
                            Text(colorMap.name)
                            if model.currentOrientation == colorMap {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(model.isRecording)
                }
            }
            CommandMenu("Capture") {
                Button(action: {
                    let panel = NSSavePanel()
                    panel.nameFieldLabel = "Save image as:"
                    panel.nameFieldStringValue = "thermal.png"
                    panel.canCreateDirectories = true
                    panel.begin { response in
                        if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                            if !model.saveImage(outputURL: fileUrl) {
                                let alert = NSAlert()
                                alert.alertStyle = .critical
                                alert.messageText = "Failed to save image"
                                alert.runModal()
                            }
                        }
                    }
                }, label: {
                    Text("Save Image")
                }).disabled(!model.isRunning)
                Button(action: {
                    let panel = NSSavePanel()
                    panel.nameFieldLabel = "Save video as:"
                    panel.nameFieldStringValue = "recording.mp4"
                    panel.canCreateDirectories = true
                    panel.begin { response in
                        if response == NSApplication.ModalResponse.OK, let fileUrl = panel.url {
                            if !model.startRecording(outputURL: fileUrl) {
                                let alert = NSAlert()
                                alert.alertStyle = .critical
                                alert.messageText = "Failed to start recording"
                                alert.runModal()
                            }
                        }
                    }
                }, label: {
                    Text("Record")
                }).disabled(model.isRecording || !model.isRunning)
                Button(action: {
                    model.stopRecording()
                }, label: {
                    Text("Stop Recording")
                }).disabled(!model.isRecording)
            }
        }
    }
}
