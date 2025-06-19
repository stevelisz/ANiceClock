import SwiftUI

struct ElegantClockView: View {
    @Binding var currentTime: Date
    @Binding var brightness: Double
    @Binding var isNightMode: Bool
    @Binding var isAutoNightMode: Bool
    @Binding var showSettings: Bool
    @Binding var is24HourFormat: Bool
    @Binding var showSeconds: Bool
    @Binding var showDate: Bool
    @Binding var showWeather: Bool
    @Binding var showBattery: Bool
    @Binding var showCalendar: Bool
    @Binding var nightColorTheme: NightColorTheme
    @Binding var fontFamily: FontFamily
    @Binding var batteryLevel: Float
    @Binding var isCharging: Bool
    @Binding var deviceOrientation: UIDeviceOrientation
    @Binding var viewMode: ViewMode
    
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var calendarService: CalendarService
    
    // New weather display settings
    let showHumidity: Bool
    let showUVIndex: Bool
    let showWindSpeed: Bool
    let temperatureUnit: TemperatureUnit
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                // Main elegant layout
                if geometry.size.width > geometry.size.height {
                    elegantLandscapeLayout(geometry: geometry)
                } else {
                    elegantPortraitLayout(geometry: geometry)
                }
                
                // Settings button (top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // View Mode Toggle
                            Button(action: {
                                viewMode = (viewMode == .clock) ? .gallery : .clock
                            }) {
                                Image(systemName: viewMode == .clock ? "photo.on.rectangle" : "clock")
                                    .font(fontFamily.font(size: 16))
                                    .foregroundColor(textColor.opacity(0.4))
                            }
                            
                            // Settings button
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(fontFamily.font(size: 18))
                                    .foregroundColor(textColor.opacity(0.4))
                            }
                        }
                    }
                    .padding(.top, 30)
                    .padding(.trailing, 30)
                    
                    Spacer()
                }
            }
        }
    }
    
    // Computed properties
    private var backgroundColor: Color {
        Color.black
    }
    
    private var textColor: Color {
        let baseColor: Color
        if isNightMode {
            baseColor = nightColorTheme.color
        } else {
            baseColor = Color.white
        }
        return baseColor.opacity(brightness)
    }
    
    private var batteryColor: Color {
        // Handle invalid battery level (simulator or monitoring disabled)
        guard batteryLevel >= 0 else {
            return Color.white.opacity(brightness)
        }
        
        if batteryLevel < 0.2 {
            return Color.red
        } else if batteryLevel < 0.3 {
            return Color.orange
        } else {
            return Color.white.opacity(brightness)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Force consistent formatting
        if is24HourFormat {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    @ViewBuilder
    private func elegantWeatherSection() -> some View {
        if let current = weatherService.currentWeather {
            HStack(spacing: 12) {
                Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                    .font(fontFamily.font(size: 24))
                    .opacity(brightness)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedTemperature(current.main.temp))
                        .font(fontFamily.font(size: 20, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text(current.weather.first?.description.capitalized ?? "Clear")
                        .font(fontFamily.font(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    let locationName = weatherService.selectedCity?.name ?? weatherService.currentLocationName ?? "Location Unknown"
                    Text(locationName)
                        .font(fontFamily.font(size: 10))
                        .foregroundColor(textColor.opacity(0.5))
                    
                    // Additional weather details for portrait mode
                    VStack(alignment: .leading, spacing: 1) {
                        if showHumidity {
                            HStack(spacing: 4) {
                                Text("Humidity")
                                    .font(fontFamily.font(size: 10, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.4))
                                Text("\(current.main.humidity)%")
                                    .font(fontFamily.font(size: 10))
                                    .foregroundColor(textColor.opacity(0.6))
                                Spacer()
                            }
                        }
                        
                        if showUVIndex && current.current.uvIndex > 0 {
                            HStack(spacing: 4) {
                                Text("UV Index")
                                    .font(fontFamily.font(size: 10, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.4))
                                Text(String(format: "%.1f", current.current.uvIndex))
                                    .font(fontFamily.font(size: 10))
                                    .foregroundColor(textColor.opacity(0.6))
                                Spacer()
                            }
                        }
                        
                        if showWindSpeed && current.current.windSpeed > 0 {
                            HStack(spacing: 4) {
                                Text("Wind")
                                    .font(fontFamily.font(size: 10, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.4))
                                Text(String(format: "%.0f km/h", current.current.windSpeed))
                                    .font(fontFamily.font(size: 10))
                                    .foregroundColor(textColor.opacity(0.6))
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 3)
                }
            }
        }
    }
    
    @ViewBuilder
    private func elegantWeatherSectionLandscape() -> some View {
        if let current = weatherService.currentWeather {
            HStack(spacing: 12) {
                Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                    .font(fontFamily.font(size: 24))
                    .opacity(brightness)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Temperature and location on same line for landscape
                    HStack(spacing: 8) {
                        Text(formattedTemperature(current.main.temp))
                            .font(fontFamily.font(size: 20, weight: .medium))
                            .foregroundColor(textColor)
                        
                        let locationName = weatherService.selectedCity?.name ?? weatherService.currentLocationName ?? "Location Unknown"
                        Text(locationName)
                            .font(fontFamily.font(size: 20, weight: .light))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    // Additional weather details for landscape mode
                    VStack(alignment: .leading, spacing: 2) {
                        if showHumidity {
                            HStack(spacing: 6) {
                                Text("Humidity")
                                    .font(fontFamily.font(size: 12, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.5))
                                Text("\(current.main.humidity)%")
                                    .font(fontFamily.font(size: 12))
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                            }
                        }
                        
                        if showUVIndex && current.current.uvIndex > 0 {
                            HStack(spacing: 6) {
                                Text("UV Index")
                                    .font(fontFamily.font(size: 12, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.5))
                                Text(String(format: "%.1f", current.current.uvIndex))
                                    .font(fontFamily.font(size: 12))
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                            }
                        }
                        
                        if showWindSpeed && current.current.windSpeed > 0 {
                            HStack(spacing: 6) {
                                Text("Wind")
                                    .font(fontFamily.font(size: 12, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.5))
                                Text(String(format: "%.0f km/h", current.current.windSpeed))
                                    .font(fontFamily.font(size: 12))
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 6)
                    
                    Text(current.weather.first?.description.capitalized ?? "Clear")
                        .font(fontFamily.font(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
        }
    }
    
    @ViewBuilder
    private func elegantCalendarSection() -> some View {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        let currentDay = calendar.component(.day, from: today)
        
        VStack(spacing: 12) {
            // Month header
            Text(DateFormatter().monthSymbols[currentMonth - 1])
                .font(fontFamily.font(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.8))
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(fontFamily.font(size: 10))
                        .foregroundColor(textColor.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid - simplified
            let firstOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
            let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<35, id: \.self) { index in
                    let dayNumber = index - firstWeekday + 1
                    
                    if dayNumber > 0 && dayNumber <= daysInMonth {
                        Text("\(dayNumber)")
                            .font(fontFamily.font(size: 11))
                            .foregroundColor(dayNumber == currentDay ? .black : textColor.opacity(0.8))
                            .frame(width: 20, height: 20)
                            .background(
                                dayNumber == currentDay ? 
                                    Circle().fill(textColor.opacity(0.9)) : 
                                    Circle().fill(Color.clear)
                            )
                    } else {
                        Text("")
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func elegantStatusBar() -> some View {
        HStack {
            // Battery indicator
            if showBattery {
                HStack(spacing: 6) {
                    Image(systemName: isCharging ? "battery.100.bolt" : "battery.100")
                        .font(fontFamily.font(size: 12))
                        .foregroundColor(batteryColor)
                    
                    if batteryLevel >= 0 {
                        Text("\(Int(batteryLevel * 100))%")
                            .font(fontFamily.font(size: 12))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Brightness control
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .font(fontFamily.font(size: 10))
                    .foregroundColor(textColor.opacity(0.4))
                
                Slider(value: $brightness, in: 0.1...1.0)
                    .frame(width: 80)
                    .accentColor(textColor.opacity(0.4))
                    .scaleEffect(0.8)
                    // .onChange(of: brightness) { _, newValue in
                    //     print("🔆 Brightness slider changed to: \(newValue)")
                    // }
                
                Image(systemName: "sun.max")
                    .font(fontFamily.font(size: 10))
                    .foregroundColor(textColor.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private func elegantPortraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main time display - centered and prominent
            VStack(spacing: 16) {
                Text(timeString)
                    .font(fontFamily.font(
                        size: min(geometry.size.width * 0.18, 80),
                        weight: .ultraLight
                    ))
                    .foregroundColor(textColor)
                    .monospacedDigit()
                
                if showDate {
                    Text(dateString)
                        .font(fontFamily.font(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Bottom section with info
            VStack(spacing: 24) {
                // Weather and calendar row
                HStack(spacing: 40) {
                    // Weather info
                    if showWeather && weatherService.currentWeather != nil {
                        elegantWeatherSection()
                    }
                    
                    Spacer()
                    
                    // Calendar
                    if showCalendar {
                        elegantCalendarSection()
                    }
                }
                .padding(.horizontal, 30)
                
                // Status bar
                elegantStatusBar()
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func elegantLandscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left side - Time and weather
            VStack(spacing: 24) {
                Spacer()
                
                // Time display
                VStack(spacing: 12) {
                    Text(timeString)
                        .font(fontFamily.font(
                            size: min(geometry.size.width * 0.11, 65),
                            weight: .ultraLight
                        ))
                        .foregroundColor(textColor)
                        .monospacedDigit()
                    
                    if showDate {
                        Text(dateString)
                            .font(fontFamily.font(size: 16, weight: .light))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }
                
                // Weather below time
                if showWeather && weatherService.currentWeather != nil {
                    elegantWeatherSectionLandscape()
                        .padding(.top, 20)
                }
                
                Spacer()
                
                // Status bar at bottom
                elegantStatusBar()
            }
            .frame(maxWidth: geometry.size.width * 0.6)
            .padding(.leading, 40)
            
            Spacer()
            
            // Right side - Calendar
            VStack {
                Spacer()
                if showCalendar {
                    elegantCalendarSection()
                        .frame(maxWidth: 280)
                }
                Spacer()
            }
            .frame(maxWidth: geometry.size.width * 0.4)
            .padding(.trailing, 40)
        }
    }
    
    private func formattedTemperature(_ celsiusTemp: Double) -> String {
        let convertedTemp = temperatureUnit.convert(temperature: celsiusTemp, from: .celsius)
        return "\(Int(convertedTemp.rounded()))\(temperatureUnit.rawValue)"
    }
} 