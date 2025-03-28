//
//  SwiftUIView.swift
//  IrProCapture
//
//  Created by Chris Greening on 21/3/25.
//

import SwiftUI

struct ColorMapDisplay: View {
    private let format: TemperatureFormat
    private let colorMap: ColorMap
    private let maxTemperature: Float
    private let minTemperature: Float
    
    init(colorMap: ColorMap, maxTemperature: Float, minTemperature: Float, format: TemperatureFormat) {
        self.colorMap = colorMap
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.format = format
    }
    
    var body: some View {
        HStack {
            VStack {
                Text(format.format(format.convert(maxTemperature)))
                Spacer()
                Text(format.format(format.convert(minTemperature)))
            }
            LinearGradient(gradient: Gradient(colors: colorMap.colors.map { Color(red: CGFloat($0.r), green: CGFloat($0.g), blue: CGFloat($0.b)) }), startPoint: .bottom, endPoint: .top)
                .frame(width: 50)
        }
    }
}

#Preview {
    ColorMapDisplay(
        colorMap: colorMaps[0],
        maxTemperature: 0.0,
        minTemperature: 40.0,
        format: .celsius
    )
}
