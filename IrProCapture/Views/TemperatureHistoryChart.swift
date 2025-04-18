//
//  TemperatureHistoryChart.swift
//  IrProCapture
//
//  Created on 21/5/25.
//

import SwiftUI
import Charts

struct TemperatureHistoryChart: View {
    private let history: [TemperatureHistoryPoint]
    private let minTemperature: Float
    private let maxTemperature: Float
    private let format: TemperatureFormat
    
    init(history: [TemperatureHistoryPoint], minTemperature: Float, maxTemperature: Float, format: TemperatureFormat) {
        self.history = history
        self.format = format
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
    }
    
    var body: some View {
        Chart(history) {
            LineMark(
                x: .value("Time", $0.timestamp),
                y: .value("Max", format.convert($0.max)),
                series: .value("", "Max")
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)
            LineMark(
                x: .value("Time", $0.timestamp),
                y: .value("Min", format.convert($0.min)),
                series: .value("", "Min")
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            LineMark(
                x: .value("Time", $0.timestamp),
                y: .value("Ave", format.convert($0.average)),
                series: .value("", "Ave")
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)
            LineMark(
                x: .value("Time", $0.timestamp),
                y: .value("Center", format.convert($0.center)),
                series: .value("", "Center")
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)
        }
        .chartForegroundStyleScale(["Max": Color.red, "Min": Color.blue, "Ave": Color.green, "Center": Color.orange])
        .chartYScale(domain: format.convert(minTemperature)...format.convert(maxTemperature))
        .chartLegend(position: .trailing, alignment: .center)
        .frame(height: 150)
        .padding(.horizontal)
    }
}

#Preview {
    let now = Date()
    let data = (0..<50).map { i in
        TemperatureHistoryPoint(
            timestamp: now.addingTimeInterval(TimeInterval(-60 + i)),
            min: 20.0 + Float.random(in: 0...2),
            max: 35.0 + Float.random(in: 0...2),
            average: 25.0 + Float.random(in: 0...2),
            center: 27.0 + Float.random(in: 0...2)
        )
    }
    
    TemperatureHistoryChart(
        history: data,
        minTemperature: 18.0,
        maxTemperature: 38.0,
        format: .celsius
    )
}
