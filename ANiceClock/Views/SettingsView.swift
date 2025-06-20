import SwiftUI
import PhotosUI

// Enhanced Settings View
struct SettingsView: View {
    @Binding var brightness: Double
    @Binding var isNightMode: Bool
    @Binding var isAutoNightMode: Bool
    @Binding var is24HourFormat: Bool
    @Binding var showSeconds: Bool
    @Binding var showDate: Bool
    @Binding var showWeather: Bool
    @Binding var showBattery: Bool
    @Binding var showCalendar: Bool
    @Binding var nightColorTheme: NightColorTheme
    @Binding var fontFamily: FontFamily
    @Binding var glassPanelOpacity: Double
    @ObservedObject var weatherService: WeatherService
    @Binding var viewMode: ViewMode
    @ObservedObject var galleryManager: GalleryManager
    @Binding var showingPhotoPicker: Bool
    @Binding var galleryDuration: Double
    @Binding var showHumidity: Bool
    @Binding var showUVIndex: Bool
    @Binding var showWindSpeed: Bool
    @Binding var temperatureUnit: TemperatureUnit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // View Mode Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("View Mode")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Display Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Display")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Brightness")
                                Spacer()
                                Slider(value: $brightness, in: 0.1...1.0)
                                    .frame(width: 150)
                                    .accentColor(.secondary)
                            }
                            Divider().padding(.leading, 20)
                            Toggle("24-Hour Time", isOn: $is24HourFormat)
                            Divider().padding(.leading, 20)
                            Toggle("Show Seconds", isOn: $showSeconds)
                            Divider().padding(.leading, 20)
                            Toggle("Show Date", isOn: $showDate)
                            Divider().padding(.leading, 20)
                            Toggle("Show Weather", isOn: $showWeather)
                            Divider().padding(.leading, 20)
                            Toggle("Show Battery", isOn: $showBattery)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Font Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Font")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Font Family")
                                Spacer()
                                Picker("Font Family", selection: $fontFamily) {
                                    ForEach(FontFamily.allCases, id: \.self) { font in
                                        Text(font.displayName).tag(font)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Night Mode Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Night Mode")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Toggle("Enable Night Mode", isOn: $isNightMode)
                            Toggle("Automatic (9pm - 7am)", isOn: $isAutoNightMode)
                                .disabled(isNightMode == false)
                            
                            // Color Theme Selection with Visual Colors
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nightmode Color Theme")
                                    .foregroundColor(isNightMode ? .primary : .secondary)
                                
                                HStack(spacing: 16) {
                                    ForEach(NightColorTheme.allCases, id: \.self) { theme in
                                        Button(action: {
                                            // Add haptic feedback for better responsiveness
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            
                                            // Update the theme with animation
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                nightColorTheme = theme
                                            }
                                        }) {
                                            Circle()
                                                .fill(theme.color)
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(nightColorTheme == theme ? Color.white : Color.clear, lineWidth: 3)
                                                        .animation(.easeInOut(duration: 0.2), value: nightColorTheme)
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(nightColorTheme == theme ? Color.gray : Color.clear, lineWidth: 1)
                                                        .animation(.easeInOut(duration: 0.2), value: nightColorTheme)
                                                )
                                                .scaleEffect(nightColorTheme == theme ? 1.1 : 1.0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: nightColorTheme)
                                        }
                                        .disabled(isNightMode == false)
                                        .opacity(isNightMode ? 1.0 : 0.5)
                                        .animation(.easeInOut(duration: 0.2), value: isNightMode)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Gallery Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Gallery")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Selected Photos")
                                Spacer()
                                Text("\(galleryManager.selectedPhotos.count)")
                                    .foregroundColor(.secondary)
                            }
                            Divider().padding(.leading, 20)
                            
                            HStack {
                                PhotoPickerView(galleryManager: galleryManager, isPresented: $showingPhotoPicker)
                                
                                Spacer()
                                
                                Button("Clear All") {
                                    galleryManager.clearAllPhotos()
                                }
                                .foregroundColor(.red)
                                .disabled(galleryManager.selectedPhotos.isEmpty)
                            }
                            Divider().padding(.leading, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Slideshow Duration")
                                    Spacer()
                                    Text("\(Int(galleryDuration))s")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(
                                    value: $galleryDuration,
                                    in: 5...60,
                                    step: 5
                                )
                                .onChange(of: galleryDuration) { _, newValue in
                                    galleryManager.updateSlideshowDuration(newValue)
                                }
                            }
                            Divider().padding(.leading, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Info Panel Transparency")
                                    Spacer()
                                    Text("\(Int((1.0 - glassPanelOpacity) * 100))%")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { 1.0 - glassPanelOpacity },
                                        set: { glassPanelOpacity = 1.0 - $0 }
                                    ),
                                    in: 0...1,
                                    step: 0.05
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Weather Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weather")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Picker("Location", selection: $weatherService.selectedCity) {
                                Text("Current Location").tag(nil as WeatherCity?)
                                ForEach(weatherService.availableCities) { city in
                                    Text(city.displayName).tag(city as WeatherCity?)
                                }
                            }
                            .onChange(of: weatherService.selectedCity) { _, _ in
                                weatherService.fetchWeather()
                            }
                            
                            Divider().padding(.leading, 20)
                            
                            // Temperature Unit Selection
                            HStack {
                                Text("Temperature Unit")
                                Spacer()
                                Picker("Temperature Unit", selection: $temperatureUnit) {
                                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Divider().padding(.leading, 20)
                            
                            // Weather Details Toggles
                            Toggle("Show Humidity", isOn: $showHumidity)
                                .disabled(!showWeather)
                            
                            Divider().padding(.leading, 20)
                            
                            Toggle("Show UV Index", isOn: $showUVIndex)
                                .disabled(!showWeather)
                            
                            Divider().padding(.leading, 20)
                            
                            Toggle("Show Wind Speed", isOn: $showWindSpeed)
                                .disabled(!showWeather)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}