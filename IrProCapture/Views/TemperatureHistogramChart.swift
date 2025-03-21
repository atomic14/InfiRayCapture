//
//  TemperatureHistogramChart.swift
//  IrProCapture
//
//  Created by Chris Greening on 21/3/25.
//

import SwiftUI
import Charts

struct TemperatureHistogramChart: View {
    private let histogram: [HistogramPoint]
    private let minTemperature: Float
    private let maxTemperature: Float
    
    init(histogram: [HistogramPoint], minTemperature: Float, maxTemperature: Float) {
        self.histogram = histogram
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
    }
    
    var body: some View {
        Chart(histogram) {
            LineMark(
                x: .value("Count", $0.y),
                y: .value("Temperature", $0.x)
            ).interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: minTemperature...maxTemperature)
        .chartXAxis(.hidden)
        .frame(width: 100)
    }
}

#Preview {
    TemperatureHistogramChart(
        histogram: (0...100).map { HistogramPoint(x: Float($0), y: 1 + Int(100 * sin(Float($0)/3.14))) },
        minTemperature: 0.0,
        maxTemperature: 100.0
    )
}
