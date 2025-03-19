//
//  ContentView.swift
//  IrProCapture
//
//  Created by Chris Greening on 16/3/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var model: Camera
    @State var isRunning = false
    @State private var alertMessage: String? = nil
    
    var body: some View {
        HStack {
            if isRunning {
                if let image = model.resultImage {
                    ZStack {
                        // the image
                        Image(image, scale: 1.0, label: Text("Temperature"))
                            .resizable()        // Make the image resizable
                            .scaledToFit()      // Scale it to fit the container, maintaining aspect ratio
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    Spacer()
                }
            } else {
                Spacer()
                Button("Start Camera") {
                    do {
                        isRunning = try model.start()
                    } catch let error as IrProError {
                        // Handle the error and show the alert
                        alertMessage = error.rawValue
                    } catch {
                        alertMessage = "Unknown error occurred"
                    }
                }
            }
            Spacer()
            VStack {
                Text(String(format: "%.1f", model.maxTemperature))
                Spacer()
                Text(String(format: "%.1f", model.minTemperature))
            }
            LinearGradient(gradient: Gradient(colors: model.currentColorMap.colors.map { Color(red: CGFloat($0.r), green: CGFloat($0.g), blue: CGFloat($0.b)) }), startPoint: .bottom, endPoint: .top)
                .frame(width: 50)
            Chart(model.histogram) {
                LineMark(
                    x: .value("Count", $0.y),
                    y: .value("Temperature", $0.x)
                ).interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: model.minTemperature...model.maxTemperature)
            .chartXAxis(.hidden)
            .frame(width: 100)
        }
        .padding()
        .onAppear {
        }
        .onDisappear() {
            model.stop()
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
}

