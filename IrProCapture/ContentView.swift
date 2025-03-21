//
//  ContentView.swift
//  IrProCapture
//
//  Created by Chris Greening on 16/3/25.
//

import SwiftUI
import Charts
import Foundation

struct ContentView: View {
    @EnvironmentObject var model: Camera
    @State var isRunning = false
    @State private var alertMessage: String? = nil

    var body: some View {
        VStack {
            CaptureToolbar()
                .padding(.top)
            HStack {
                if let image = model.resultImage {
                    // the image
                    Image(image, scale: 1.0, label: Text("Temperature"))
                        .resizable()        // Make the image resizable
                        .scaledToFit()      // Scale it to fit the container, maintaining aspect ratio
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Spacer()
                }
                Spacer()
                ColorMapDisplay(colorMap: model.currentColorMap, maxTemperature: model.maxTemperature, minTemperature: model.minTemperature)
                TemperatureHistogramChart(
                    histogram: model.histogram,
                    minTemperature: model.minTemperature,
                    maxTemperature: model.maxTemperature
                )
            }.padding()
            
            // History chart at the bottom
            TemperatureHistoryChart(
                history: model.temperatureHistory,
                minTemperature: model.temperatureHistory.isEmpty ? model.minTemperature : model.temperatureHistory.map { $0.min }.min() ?? model.minTemperature,
                maxTemperature: model.temperatureHistory.isEmpty ? model.maxTemperature : model.temperatureHistory.map { $0.max }.max() ?? model.maxTemperature
            )
            .padding(.bottom)
        }
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

#Preview {
    ContentView()
    .environmentObject(Camera())
}
