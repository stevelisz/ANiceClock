import SwiftUI

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
    @ObservedObject var weatherService: WeatherService
    @Binding var viewMode: ViewMode
    @ObservedObject var galleryManager: GalleryManager
    @Binding var showingPhotoPicker: Bool
    @Binding var galleryDuration: Double
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
                    
                    // Night Mode Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Night Mode")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Toggle("Enable Night Mode", isOn: $isNightMode)
                            Toggle("Automatic (9pm - 7am)", isOn: $isAutoNightMode)
                                .disabled(isNightMode == false)
                            
                            Picker("Color Theme", selection: $nightColorTheme) {
                                ForEach(NightColorTheme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .disabled(isNightMode == false)
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
                            Button(action: {
                                showingPhotoPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Select Photos")
                                }
                            }
                            
                            HStack {
                                Text("Slideshow Speed")
                                Spacer()
                                Slider(value: $galleryDuration, in: 3...30, step: 1)
                                    .frame(width: 150)
                                    .accentColor(.secondary)
                                    .onChange(of: galleryDuration) { _, newValue in
                                        galleryManager.slideshowDuration = newValue
                                    }
                                Text("\(Int(galleryDuration))s")
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
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoCollectionPickerView(galleryManager: galleryManager)
            }
        }
    }
} 