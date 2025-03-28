import SwiftUI

/// A view for configuring temperature grid settings.
///
/// This view allows users to:
/// - Toggle grid visibility
/// - Select grid density
/// - Choose temperature display format
struct TemperatureGridSettingsView: View {
    @EnvironmentObject var camera: Camera
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Show Grid", isOn: $camera.showTemperatureGrid)
                .toggleStyle(.switch)
            
            Text("Grid Density")
                .font(.headline)
            
            Picker("Grid Density", selection: $camera.temperatureGridDensity) {
                ForEach(GridDensity.allCases) { density in
                    Text(density.rawValue).tag(density)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Temperature Format")
                .font(.headline)
            
            Picker("Temperature Format", selection: $camera.temperatureFormat) {
                ForEach(TemperatureFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .frame(width: 200)
    }
} 