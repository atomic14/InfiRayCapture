import Foundation
import Accelerate


struct TemperatureResult {
    let temperatures: [Float]
    let min: Float
    let max: Float
    let maxX: Float
    let maxY: Float
    let average: Float
    let center: Float
    let histogram: [HistogramPoint]
}

struct HistogramPoint: Identifiable {
    var id: Float { x }
    var x: Float
    var y: Int
}

class TemperatureProcessor {
    private let width: Int = 256
    private let height: Int = 192
        
    func computeHistogram(values: [Float], min: Float, max: Float, bins: Int) -> [HistogramPoint] {
        let range = max - min
        let binWidth = range / Float(bins - 1)
        if (binWidth == 0) {
            return []
        }
        // work out which bin each value falls in
        let binIndexes = vDSP.multiply(1/binWidth, vDSP.add(-min, values))
        // accumulate the histogram
        var histogram = [Int](repeating: 0, count: bins)
        binIndexes.forEach { histogram[Int($0)] += 1 }
        // results for charting
        return histogram.enumerated().map { (index, element) in
            HistogramPoint(x: Float(index) * binWidth + min, y: element)
        }
    }
    
    func getTemperatures(from buffer: UnsafeMutablePointer<UInt16>, bytesPerRow: Int, startingAtRow: Int = 192) -> TemperatureResult {
        
        // Step 1 - get the bytes into the right order
        var swappedValues = [UInt16](repeating: 0, count: width * height)
        var dstIndex = 0
        for row in startingAtRow..<(startingAtRow + height) {
            var srcIndex = row * bytesPerRow / MemoryLayout<UInt16>.size
            for _ in 0..<width {
                let value = buffer[srcIndex].byteSwapped
                swappedValues[dstIndex] = value
                dstIndex += 1
                srcIndex += 1
            }
        }
        // Step 2: Convert UInt16 to Float
        var temperatures = [Float](repeating: 0, count: width * height)
        vDSP_vfltu16(swappedValues, 1, &temperatures, 1, vDSP_Length(width*height))

        // Step 3: Apply conversion: `(raw / 64.0) - 273.2`
        let scale: Float = 1.0 / 64.0
        let offset: Float = -273.2
        temperatures = vDSP.add(offset, vDSP.multiply(scale, temperatures))

        // Calculate statistics
        let minValue = temperatures.min() ?? 0.0
        let maxElement = temperatures.enumerated().max(by: { $0.element < $1.element })
        let maxValue = maxElement?.element ?? 0.0
        let sum = temperatures.reduce(0, { $0 + $1 })
        let average = sum / Float(temperatures.count)
        let centerIndex = width * (height / 2) + (width / 2)
        let centerTemp = temperatures[centerIndex]
        let maxX = Float((maxElement?.offset ?? 0) % 256) / 256.0
        let maxY = Float((maxElement?.offset ?? 0) / 256) / 192.0

        // Compute histogram
        let histogram = computeHistogram(values: temperatures, min: minValue, max: maxValue, bins: 50)
        
        return TemperatureResult(
            temperatures: temperatures,
            min: minValue,
            max: maxValue,
            maxX: maxX,
            maxY: maxY,
            average: average,
            center: centerTemp,
            histogram: histogram
        )
    }
} 
