//
//  UIState.swift
//  IrProCapture
//
//  Created by Chris Greening on 28/3/25.
//
import Foundation

/// Enum representing different grid density options
enum GridDensity: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    /// Grid dimensions as (rows, columns)
    var dimensions: (Int, Int) {
        switch self {
            case .low: return (5, 5)
            case .medium: return (9, 9)
            case .high: return (15, 15)
        }
    }
}

/// Enum representing temperature display formats
enum TemperatureFormat: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    var id: String { self.rawValue }
    
    func convert(_ temperature: Float) -> Float {
        switch self {
        case .celsius:
            return temperature
        case .fahrenheit:
            return temperature * 9.0/5.0 + 32.0
        }
    }
    
    /// Converts a Celsius temperature to the selected format
    func format(_ temperature: Float) -> String {
        switch self {
        case .celsius:
            return String(format: "%.1f°C", temperature)
        case .fahrenheit:
            return String(format: "%.1f°F", temperature)
        }
    }
}

class UIState: ObservableObject {
    /// The currently selected color map for thermal visualization
    @Published var currentColorMap: ColorMap {
        didSet {
            UserDefaults.standard.set(colorMaps.firstIndex(of: currentColorMap)!, forKey: "currentColorMap")
        }
    }
    
    /// The current orientation setting for the thermal image
    @Published var currentOrientation: OrientationOption {
        didSet {
            UserDefaults.standard.set(orientationOptions.firstIndex(of: currentOrientation)!, forKey: "currentOrientation")
            print("Orientation changed to \(currentOrientation)")
        }
    }
    /// The current grid density setting
    @Published var temperatureGridDensity: GridDensity {
        didSet {
            UserDefaults.standard.set(temperatureGridDensity.rawValue, forKey: "temperatureGridDensity")
        }
    }
    
    /// Whether to show the temperature grid overlay
    @Published var showTemperatureGrid: Bool {
        didSet {
            UserDefaults.standard.set(showTemperatureGrid, forKey: "showTemperatureGrid")
        }
    }
    
    /// The temperature format to use (Celsius or Fahrenheit)
    @Published var temperatureFormat: TemperatureFormat {
        didSet {
            UserDefaults.standard.set(temperatureFormat.rawValue, forKey: "temperatureFormat")
        }
    }
    
    /// Indicates whether the camera is currently running
    @Published var isRunning = false
    
    /// Indicates whether video recording is in progress
    @Published var isRecording = false
    
    init() {
        // Initialise any user defaults
        let colorMapIndex = UserDefaults.standard.integer(forKey: "currentColorMap")
        if colorMapIndex >= 0 && colorMapIndex < colorMaps.count {
            self.currentColorMap = colorMaps[colorMapIndex]
        } else {
            self.currentColorMap = colorMaps[0]
            UserDefaults.standard.set(0, forKey: "currentColorMap")
        }
        let currentOrientationIndex = UserDefaults.standard.integer(forKey: "currentOrientation")
        if currentOrientationIndex >= 0 || currentOrientationIndex < orientationOptions.count {
            self.currentOrientation = orientationOptions[UserDefaults.standard.integer(forKey: "currentOrientation")]
        } else {
            self.currentOrientation = orientationOptions[7]
            UserDefaults.standard.set(7, forKey: "currentOrientation")
        }
        
        // Initialize temperature grid settings
        let gridDensityString = UserDefaults.standard.string(forKey: "temperatureGridDensity") ?? GridDensity.medium.rawValue
        if let gridDensity = GridDensity.allCases.first(where: { $0.rawValue == gridDensityString }) {
            self.temperatureGridDensity = gridDensity
        } else {
            self.temperatureGridDensity = .medium
            UserDefaults.standard.set(GridDensity.medium.rawValue, forKey: "temperatureGridDensity")
        }
        
        self.showTemperatureGrid = UserDefaults.standard.bool(forKey: "showTemperatureGrid")
        
        let temperatureFormatString = UserDefaults.standard.string(forKey: "temperatureFormat") ?? TemperatureFormat.celsius.rawValue
        if let format = TemperatureFormat.allCases.first(where: { $0.rawValue == temperatureFormatString }) {
            self.temperatureFormat = format
        } else {
            self.temperatureFormat = .celsius
            UserDefaults.standard.set(TemperatureFormat.celsius.rawValue, forKey: "temperatureFormat")
        }
    }
    
    /// Cycles to the next orientation option
    func nextOrientation() {
        guard !isRecording else { return }
        
        if let currentIndex = orientationOptions.firstIndex(of: currentOrientation) {
            let nextIndex = (currentIndex + 1) % orientationOptions.count
            currentOrientation = orientationOptions[nextIndex]
        }
    }
    
    /// Cycles to the previous orientation option
    func previousOrientation() {
        guard !isRecording else { return }
        
        if let currentIndex = orientationOptions.firstIndex(of: currentOrientation) {
            let previousIndex = (currentIndex - 1 + orientationOptions.count) % orientationOptions.count
            currentOrientation = orientationOptions[previousIndex]
        }
    }

}
