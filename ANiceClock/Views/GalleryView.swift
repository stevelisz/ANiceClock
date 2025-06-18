import SwiftUI

// MARK: - Main Gallery View
struct GalleryView: View {
    let currentTime: Date
    let brightness: Double
    let is24HourFormat: Bool
    let showSeconds: Bool
    let showDate: Bool
    let showWeather: Bool
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var galleryManager: GalleryManager
    let onTapToGoBack: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Photo Layer - Fill entire screen
                GalleryBackgroundView(galleryManager: galleryManager)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Fixed Position Info Panel - Absolutely positioned to screen coordinates
                GalleryInfoPanel(
                    currentTime: currentTime,
                    brightness: brightness,
                    is24HourFormat: is24HourFormat,
                    showSeconds: showSeconds,
                    showDate: showDate,
                    showWeather: showWeather,
                    weatherService: weatherService,
                    onTapToGoBack: onTapToGoBack
                )
                .position(
                    x: 24 + (GalleryInfoPanel.estimatedWidth / 2), // Fixed X position from left edge
                    y: geometry.size.height - max(32, geometry.safeAreaInsets.bottom + 16) - (GalleryInfoPanel.estimatedHeight / 2) // Fixed Y position from bottom
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Ensure we have a current image loaded when gallery view appears
            galleryManager.ensureCurrentImageLoaded()
        }
    }
}

// MARK: - Gallery Background View
struct GalleryBackgroundView: View {
    @ObservedObject var galleryManager: GalleryManager
    
    var body: some View {
        Group {
            if let backgroundImage = galleryManager.currentDisplayImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut(duration: 1.0)))
            } else {
                // Default gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color.gray.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Gallery Info Panel
struct GalleryInfoPanel: View {
    let currentTime: Date
    let brightness: Double
    let is24HourFormat: Bool
    let showSeconds: Bool
    let showDate: Bool
    let showWeather: Bool
    @ObservedObject var weatherService: WeatherService
    let onTapToGoBack: () -> Void
    
    // Static size estimates for positioning calculations
    static let estimatedWidth: CGFloat = 300
    static let estimatedHeight: CGFloat = 140
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Time Display - Primary hierarchy
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(galleryTimeString)
                    .font(.system(size: 48, weight: .light, design: .default))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 0)
                
                if showSeconds {
                    Text(gallerySecondsString)
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 1, y: 1)
                        .offset(y: -6)
                }
            }
            
            // Date Display - Secondary hierarchy
            if showDate {
                Text(galleryDateString)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 1, y: 1)
                    .padding(.top, 2)
            }
            
            // Weather & Location Display - Tertiary hierarchy
            if showWeather, let current = weatherService.currentWeather {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                            .font(.system(size: 20))
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                        
                        Text("\(Int(current.main.temp.rounded()))°")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.7), radius: 3, x: 1, y: 1)
                        
                        Spacer()
                    }
                    
                    // Location Display
                    let locationName = weatherService.selectedCity?.name ?? weatherService.currentLocationName ?? "Unknown Location"
                    if !locationName.isEmpty && locationName != "Unknown Location" {
                        Text(locationName)
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            // Native Glass Effect
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.7) // Make it more transparent
                .environment(\.colorScheme, .dark) // Force dark mode for glass effect
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .overlay(
                    // Subtle inner glow
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(maxWidth: Self.estimatedWidth)
        .onTapGesture {
            onTapToGoBack()
        }
    }
    
    // MARK: - Time Formatting Helpers
    private var galleryTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm"
        return formatter.string(from: currentTime)
    }
    
    private var gallerySecondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }
    
    private var galleryDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: currentTime)
    }
    
    private func weatherIconForCondition(_ condition: String) -> String {
        switch condition.lowercased() {
        case "clear": return "☀️"
        case "clouds": return "☁️"
        case "rain": return "🌧️"
        case "drizzle": return "🌦️"
        case "thunderstorm": return "⛈️"
        case "snow": return "❄️"
        case "mist", "fog", "haze": return "🌫️"
        default: return "☀️"
        }
    }
}