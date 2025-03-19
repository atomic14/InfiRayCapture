import Foundation

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
    
    @inline(__always)
    func convertTemp<T: BinaryInteger>(raw: T) -> Float {
        return Float(raw) / 64.0 - 273.2
    }
    
    func computeHistogram(values: [Float], min: Float, max: Float, bins: Int) -> [HistogramPoint] {
        var histogram = [Int](repeating: 0, count: bins)
        
        // Ensure values are within the specified range
        let range = max - min
        let binWidth = range / Float(bins)
        if (binWidth == 0) {
            return []
        }

        // Iterate through each value
        for value in values {
            // Skip values that are outside the given range
            if value < min || value > max {
                continue
            }
            
            // Find the appropriate bin for the value
            let binIndex = Int((value - min) / binWidth)
            
            // Make sure binIndex is within bounds
            if binIndex >= 0 && binIndex < bins {
                histogram[binIndex] += 1
            }
        }
        
        return histogram.enumerated().map { (index, element) in
            HistogramPoint(x: Float(index) * binWidth + min, y: element)
        }
    }
    
    func getTemperatures(from buffer: UnsafePointer<UInt16>, bytesPerRow: Int, startingAtRow: Int = 192) -> TemperatureResult {
        var temperatures = [Float](repeating: 0, count: width * height)
        var dstIndex = 0
        
        // Process the temperature data
        for row in startingAtRow..<(startingAtRow + height) {
            for column in 0..<width {
                let index = row * bytesPerRow / MemoryLayout<UInt16>.size + column
                let value = buffer[index].byteSwapped
                temperatures[dstIndex] = convertTemp(raw: value)
                dstIndex += 1
            }
        }
        
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
