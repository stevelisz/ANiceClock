import SwiftUI

// MARK: - Main Gallery View
struct GalleryView: View {
    let currentTime: Date
    let brightness: Double
    let is24HourFormat: Bool
    let showSeconds: Bool
    let showDate: Bool
    let showWeather: Bool
    let glassPanelOpacity: Double
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var galleryManager: GalleryManager
    let onTapToGoBack: () -> Void
    
    // State for draggable glass panel
    @State private var panelPosition: CGPoint
    @State private var dragStartPosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var isInitialLoad = true
    
    // UserDefaults keys for persistent panel position
    private let panelPositionXKey = "ANiceClock_GalleryPanelX"
    private let panelPositionYKey = "ANiceClock_GalleryPanelY"
    
    // Initialize with saved position or default
    init(currentTime: Date, brightness: Double, is24HourFormat: Bool, showSeconds: Bool, showDate: Bool, showWeather: Bool, glassPanelOpacity: Double, weatherService: WeatherService, galleryManager: GalleryManager, onTapToGoBack: @escaping () -> Void) {
        self.currentTime = currentTime
        self.brightness = brightness
        self.is24HourFormat = is24HourFormat
        self.showSeconds = showSeconds
        self.showDate = showDate
        self.showWeather = showWeather
        self.glassPanelOpacity = glassPanelOpacity
        self.weatherService = weatherService
        self.galleryManager = galleryManager
        self.onTapToGoBack = onTapToGoBack
        
        // Load saved position immediately to prevent flying animation
        let savedX = UserDefaults.standard.object(forKey: "ANiceClock_GalleryPanelX") as? Double
        let savedY = UserDefaults.standard.object(forKey: "ANiceClock_GalleryPanelY") as? Double
        
        if let x = savedX, let y = savedY {
            _panelPosition = State(initialValue: CGPoint(x: x, y: y))
        } else {
            let defaultPos = Self.defaultPanelPosition(in: UIScreen.main.bounds)
            _panelPosition = State(initialValue: defaultPos)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Photo Layer - Fill entire screen
                GalleryBackgroundView(galleryManager: galleryManager)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Draggable Info Panel - Now with free positioning
                GalleryInfoPanel(
                    currentTime: currentTime,
                    brightness: brightness,
                    is24HourFormat: is24HourFormat,
                    showSeconds: showSeconds,
                    showDate: showDate,
                    showWeather: showWeather,
                    glassPanelOpacity: glassPanelOpacity,
                    weatherService: weatherService,
                    onTapToGoBack: onTapToGoBack,
                    isDragging: isDragging
                )
                .position(panelPosition)
                .gesture(
                    // Combined tap and drag gesture
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                // Store the starting position when drag begins
                                isDragging = true
                                dragStartPosition = panelPosition
                            }
                            // Calculate new position from drag start + translation
                            let newPosition = CGPoint(
                                x: dragStartPosition.x + value.translation.width,
                                y: dragStartPosition.y + value.translation.height
                            )
                            // Apply constraints to keep panel on screen
                            panelPosition = CGPoint(
                                x: constrainX(newPosition.x, in: geometry),
                                y: constrainY(newPosition.y, in: geometry)
                            )
                        }
                        .onEnded { value in
                            let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            
                            if dragDistance < 10 {
                                // This was a tap (very small movement)
                                onTapToGoBack()
                            } else {
                                // This was a drag - save the new position
                                savePanelPosition()
                            }
                            isDragging = false
                        }
                )
                // Only animate after initial load to prevent flying effect
                .animation(isInitialLoad ? nil : .spring(response: 0.6, dampingFraction: 0.7), value: panelPosition)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Ensure we have a current image loaded when gallery view appears
            galleryManager.ensureCurrentImageLoaded()
            // Start the slideshow
            galleryManager.startSlideshow()
            // Mark that initial load is complete after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInitialLoad = false
            }
        }
        .onDisappear {
            // Stop slideshow when leaving gallery view
            galleryManager.stopSlideshow()
        }
    }
    
    // MARK: - Panel Position Persistence
    private func savePanelPosition() {
        UserDefaults.standard.set(Double(panelPosition.x), forKey: panelPositionXKey)
        UserDefaults.standard.set(Double(panelPosition.y), forKey: panelPositionYKey)
    }
    
    // MARK: - Panel Positioning Helpers
    private static func defaultPanelPosition(in bounds: CGRect) -> CGPoint {
        return CGPoint(
            x: 24 + (GalleryInfoPanel.estimatedWidth / 2), // Default left bottom position
            y: bounds.height - 100 - (GalleryInfoPanel.estimatedHeight / 2)
        )
    }
    
    private func constrainX(_ x: CGFloat, in geometry: GeometryProxy) -> CGFloat {
        let panelHalfWidth = GalleryInfoPanel.estimatedWidth / 2
        let margin: CGFloat = 24
        let minX = margin + panelHalfWidth
        let maxX = geometry.size.width - margin - panelHalfWidth
        return max(minX, min(maxX, x))
    }
    
    private func constrainY(_ y: CGFloat, in geometry: GeometryProxy) -> CGFloat {
        let panelHalfHeight = GalleryInfoPanel.estimatedHeight / 2
        let margin: CGFloat = 24
        let minY = geometry.safeAreaInsets.top + margin + panelHalfHeight
        let maxY = geometry.size.height - max(32, geometry.safeAreaInsets.bottom + 16) - panelHalfHeight
        return max(minY, min(maxY, y))
    }
}

// MARK: - Gallery Background View
struct GalleryBackgroundView: View {
    @ObservedObject var galleryManager: GalleryManager
    
    var body: some View {
        Group {
            if let backgroundImage = galleryManager.currentImage {
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
    let glassPanelOpacity: Double
    @ObservedObject var weatherService: WeatherService
    let onTapToGoBack: () -> Void
    let isDragging: Bool
    
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
            // Native Glass Effect with drag feedback
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(isDragging ? min(glassPanelOpacity + 0.2, 1.0) : glassPanelOpacity) // Use custom opacity, slightly more when dragging
                .environment(\.colorScheme, .dark) // Force dark mode for glass effect
                .shadow(color: .black.opacity(isDragging ? 0.5 : 0.3), radius: isDragging ? 30 : 20, x: 0, y: isDragging ? 15 : 10)
        )
        .scaleEffect(isDragging ? 1.05 : 1.0) // Slightly larger when dragging
        .frame(maxWidth: Self.estimatedWidth)
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