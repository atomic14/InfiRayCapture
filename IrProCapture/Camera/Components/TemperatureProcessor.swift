import Foundation
import Accelerate


/// A data point for historical temperature tracking
struct TemperatureHistoryPoint: Identifiable {
    /// Unique identifier for the point
    var id: Date { timestamp }
    /// Timestamp when the reading was taken
    let timestamp: Date
    /// Minimum temperature in this reading
    let min: Float
    /// Maximum temperature in this reading
    let max: Float
    /// Average temperature in this reading
    let average: Float
    /// Temperature at center point in this reading
    let center: Float
}


/// A structure containing processed temperature data and related statistics.
///
/// This structure encapsulates all the temperature-related information extracted
/// from a single thermal camera frame, including raw temperatures, statistics,
/// and histogram data for visualization.
struct TemperatureResult {
    /// Raw temperature values for each pixel
    let temperatures: [Float]
    /// Minimum temperature in the frame
    let min: Float
    /// Maximum temperature in the frame
    let max: Float
    /// X-coordinate (normalized 0-1) of the maximum temperature
    let maxX: Float
    /// Y-coordinate (normalized 0-1) of the maximum temperature
    let maxY: Float
    /// Average temperature across all pixels
    let average: Float
    /// Temperature at the center of the frame
    let center: Float
    /// Temperature distribution data for histogram visualization
    let histogram: [HistogramPoint]
    /// Temperature history
    let temperatureHistory: [TemperatureHistoryPoint]
    /// Width of the temperature data in pixels
    let width: Int
    /// Height of the temperature data in pixels
    let height: Int
}
/// A single point in the temperature histogram.
///
/// Used for visualizing temperature distribution across the thermal image.
struct HistogramPoint: Identifiable {
    /// Unique identifier for the point, using temperature as the ID
    var id: Float { x }
    /// Temperature value for this histogram bin
    var x: Float
    /// Count of pixels at this temperature
    var y: Int
}

/// A class responsible for processing raw thermal camera data into temperature values.
///
/// The TemperatureProcessor handles:
/// - Raw data conversion from camera format to temperature values
/// - Statistical analysis of temperature data
/// - Histogram generation for temperature distribution visualization
class TemperatureProcessor {
    /// Width of the thermal sensor in pixels
    private let width: Int = 256
    /// Height of the thermal sensor in pixels
    private let height: Int = 192
    
    /// Buffer storing recent frames for averaging
    private var frameBuffer: [[Float]] = []
    /// Maximum number of frames to average
    private var maxFrameCount: Int = 5
    /// Whether frame averaging is enabled
    private var averagingEnabled: Bool = false
    // Temperature history tracking
    private var temperatureHistory: [TemperatureHistoryPoint] = []
    private let historyUpdateInterval: TimeInterval = 0.1 // Update every second
    private let maxHistoryTime = 60.0 // Keep 1 minute of history

    /// Initializes a new TemperatureProcessor.
    ///
    /// - Parameters:
    ///   - averagingEnabled: Whether frame averaging is enabled (default: false)
    ///   - maxFrameCount: Maximum number of frames to keep for averaging (default: 5)
    init(averagingEnabled: Bool = false, maxFrameCount: Int = 5) {
        self.averagingEnabled = averagingEnabled
        self.maxFrameCount = max(1, maxFrameCount)
    }
    
    /// Enables or disables frame averaging.
    ///
    /// - Parameter enabled: Whether averaging should be enabled
    func setAveragingEnabled(_ enabled: Bool) {
        if averagingEnabled != enabled {
            frameBuffer.removeAll()
            averagingEnabled = enabled
        }
    }
    
    /// Sets the number of frames to use for averaging.
    ///
    /// - Parameter count: Number of frames to average (minimum 1)
    func setFrameCount(_ count: Int) {
        let newCount = max(1, count)
        if maxFrameCount != newCount {
            maxFrameCount = newCount
            // Trim buffer if needed
            while frameBuffer.count > maxFrameCount {
                frameBuffer.removeFirst()
            }
        }
    }
    
    /// Computes a histogram of temperature values.
    ///
    /// - Parameters:
    ///   - values: Array of temperature values to analyze
    ///   - min: Minimum temperature value for binning
    ///   - max: Maximum temperature value for binning
    ///   - bins: Number of histogram bins to create
    /// - Returns: Array of HistogramPoint representing the temperature distribution
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
    
    /// Records current temperature values to the history.
    /// Only adds a point if enough time has passed since the last update.
    private func updateTemperatureHistory(minTemperature: Float, maxTemperature: Float, averageTemperature: Float, centerTemperature: Float) {
        let now = Date()
        
        // Only update approximately once per second
        if temperatureHistory.isEmpty || now.timeIntervalSince(temperatureHistory.last!.timestamp) >= historyUpdateInterval {
            // Create a new history point with current values and timestamp
            let historyPoint = TemperatureHistoryPoint(
                timestamp: now,
                min: minTemperature,
                max: maxTemperature,
                average: averageTemperature,
                center: centerTemperature
            )
            
            // Add to history
            temperatureHistory.append(historyPoint)
            
            // Trim history if it exceeds the maximum time
            while temperatureHistory.count >= 2 &&
                  (temperatureHistory.last?.timestamp.timeIntervalSince1970 ?? 0) -
                  (temperatureHistory.first?.timestamp.timeIntervalSince1970 ?? 0) > maxHistoryTime {
                temperatureHistory.removeFirst()
            }
        }
    }

    
    /// Processes raw thermal camera data into temperature values and statistics.
    ///
    /// This method performs several steps:
    /// 1. Reorders the raw bytes from the camera buffer
    /// 2. Converts UInt16 values to floating-point temperatures
    /// 3. Applies calibration formula to get actual temperatures
    /// 4. Computes various statistics and histogram data
    /// 5. If enabled, averages with previous frames to reduce noise
    ///
    /// - Parameters:
    ///   - buffer: Raw camera data buffer
    ///   - bytesPerRow: Number of bytes per row in the buffer
    ///   - startingAtRow: Starting row for processing (default: 192)
    /// - Returns: A TemperatureResult containing processed data and statistics
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
        
        // Step 4: Apply frame averaging if enabled
        if averagingEnabled {
            // Add current frame to buffer
            frameBuffer.append(temperatures)
            
            // Keep buffer at correct size
            while frameBuffer.count > maxFrameCount {
                frameBuffer.removeFirst()
            }

            // Average frames if we have more than one
            if frameBuffer.count > 1 {
                var averagedTemperatures = [Float](repeating: 0, count: width * height)
                
                // Sum all frames
                for frame in frameBuffer {
                    vDSP.add(averagedTemperatures, frame, result: &averagedTemperatures)
                }
                
                // Divide by frame count
                let scale = 1.0 / Float(frameBuffer.count)
                vDSP.multiply(scale, averagedTemperatures, result: &averagedTemperatures)
                
                // Use averaged temperatures for statistics
                temperatures = averagedTemperatures
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
        // update history
        if (minValue > -20) {
            updateTemperatureHistory(minTemperature: minValue, maxTemperature: maxValue, averageTemperature: average, centerTemperature: centerTemp)
        }
        
        return TemperatureResult(
            temperatures: temperatures,
            min: minValue,
            max: maxValue,
            maxX: maxX,
            maxY: maxY,
            average: average,
            center: centerTemp,
            histogram: histogram,
            temperatureHistory: temperatureHistory,
            width: width,
            height: height
        )
    }
} 
