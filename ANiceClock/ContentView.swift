//
//  ContentView.swift
//  ANiceClock
//
//  Created by Steve Li on 6/17/25.
//

import SwiftUI
import CoreLocation
import EventKit

// Color theme options
enum NightColorTheme: String, CaseIterable {
    case red = "Red"
    case amber = "Amber"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case orange = "Orange"
    
    var color: Color {
        switch self {
        case .red: return Color.red.opacity(0.9)
        case .amber: return Color.orange.opacity(0.8)
        case .green: return Color.green.opacity(0.8)
        case .blue: return Color.blue.opacity(0.8)
        case .purple: return Color.purple.opacity(0.8)
        case .orange: return Color.orange.opacity(0.9)
        }
    }
}

// Weather data models for Open-Meteo API (Free, no API key required)
struct WeatherData: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
    let timezone: String
    
    // Computed properties for compatibility
    var main: MainWeather {
        MainWeather(temp: current.temperature_2m, feels_like: current.apparent_temperature, humidity: Int(current.relative_humidity_2m))
    }
    
    var weather: [WeatherCondition] {
        [WeatherCondition(main: weatherCodeToCondition(current.weather_code), 
                         description: weatherCodeToDescription(current.weather_code), 
                         icon: "")]
    }
    
    var name: String { timezone.components(separatedBy: "/").last ?? "Unknown" }
    var sys: WeatherSys { WeatherSys(country: "") }
}

struct CurrentWeather: Codable {
    let temperature_2m: Double
    let apparent_temperature: Double
    let relative_humidity_2m: Double
    let weather_code: Int
}

struct DailyWeather: Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let weather_code: [Int]
}

struct MainWeather: Codable {
    let temp: Double
    let feels_like: Double
    let humidity: Int
}

struct WeatherCondition: Codable {
    let main: String
    let description: String
    let icon: String
}

struct WeatherSys: Codable {
    let country: String
}

struct ForecastItem: Codable {
    let dt: Int
    let main: MainWeather
    let weather: [WeatherCondition]
    let dt_txt: String
}

// City data for weather selection
struct WeatherCity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    
    var displayName: String {
        return "\(name), \(country)"
    }
}

// Weather code conversion functions for Open-Meteo
func weatherCodeToCondition(_ code: Int) -> String {
    switch code {
    case 0: return "Clear"
    case 1, 2, 3: return "Clouds"
    case 45, 48: return "Fog"
    case 51, 53, 55, 56, 57: return "Drizzle"
    case 61, 63, 65, 66, 67: return "Rain"
    case 71, 73, 75, 77: return "Snow"
    case 80, 81, 82: return "Rain"
    case 85, 86: return "Snow"
    case 95, 96, 99: return "Thunderstorm"
    default: return "Clear"
    }
}

func weatherCodeToDescription(_ code: Int) -> String {
    switch code {
    case 0: return "clear sky"
    case 1: return "mainly clear"
    case 2: return "partly cloudy"
    case 3: return "overcast"
    case 45, 48: return "fog"
    case 51: return "light drizzle"
    case 53: return "moderate drizzle"
    case 55: return "dense drizzle"
    case 61: return "slight rain"
    case 63: return "moderate rain"
    case 65: return "heavy rain"
    case 71: return "slight snow"
    case 73: return "moderate snow"
    case 75: return "heavy snow"
    case 80: return "rain showers"
    case 95: return "thunderstorm"
    default: return "clear sky"
    }
}

// Enhanced Weather Service using Open-Meteo API (Free, no API key required)
class WeatherService: NSObject, ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: [ForecastItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCity: WeatherCity?
    @Published var availableCities: [WeatherCity] = [
        WeatherCity(name: "New York", lat: 40.7128, lon: -74.0060, country: "US"),
        WeatherCity(name: "London", lat: 51.5074, lon: -0.1278, country: "GB"),
        WeatherCity(name: "Tokyo", lat: 35.6762, lon: 139.6503, country: "JP"),
        WeatherCity(name: "Paris", lat: 48.8566, lon: 2.3522, country: "FR"),
        WeatherCity(name: "Sydney", lat: -33.8688, lon: 151.2093, country: "AU"),
        WeatherCity(name: "Los Angeles", lat: 34.0522, lon: -118.2437, country: "US"),
        WeatherCity(name: "Berlin", lat: 52.5200, lon: 13.4050, country: "DE"),
        WeatherCity(name: "Singapore", lat: 1.3521, lon: 103.8198, country: "SG"),
        WeatherCity(name: "Toronto", lat: 43.6532, lon: -79.3832, country: "CA"),
        WeatherCity(name: "Dubai", lat: 25.2048, lon: 55.2708, country: "AE")
    ]
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather() {
        if let city = selectedCity {
            // Use selected city
            fetchWeatherForLocation(lat: city.lat, lon: city.lon, cityName: city.name)
        } else {
            // Use current location
            guard locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways else {
                // Use default location (San Francisco) for demo
                fetchWeatherForLocation(lat: 37.7749, lon: -122.4194, cityName: "San Francisco")
                return
            }
            locationManager.requestLocation()
        }
    }
    
    func selectCity(_ city: WeatherCity?) {
        selectedCity = city
        fetchWeather()
    }
    
    private func fetchWeatherForLocation(lat: Double, lon: Double, cityName: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        // Open-Meteo API - Free, no API key required!
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=7"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.currentWeather = nil
                    self.forecast = []
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    self.currentWeather = nil
                    self.forecast = []
                    return
                }
                
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                    self.currentWeather = weatherData
                    self.generateForecastFromDaily(weatherData, cityName: cityName)
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Failed to decode weather data: \(error.localizedDescription)"
                    self.currentWeather = nil
                    self.forecast = []
                }
            }
        }.resume()
    }
    
    private func generateForecastFromDaily(_ weatherData: WeatherData, cityName: String?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        forecast = zip(weatherData.daily.time, zip(weatherData.daily.temperature_2m_max, weatherData.daily.weather_code)).enumerated().map { index, element in
            let (dateString, (maxTemp, weatherCode)) = element
            
            if let date = dateFormatter.date(from: dateString) {
                return ForecastItem(
                    dt: Int(date.timeIntervalSince1970),
                    main: MainWeather(temp: maxTemp, feels_like: maxTemp, humidity: 50),
                    weather: [WeatherCondition(main: weatherCodeToCondition(weatherCode), 
                                             description: weatherCodeToDescription(weatherCode), 
                                             icon: "")],
                    dt_txt: dateString
                )
            } else {
                return ForecastItem(
                    dt: Int(Date().timeIntervalSince1970) + (index * 86400),
                    main: MainWeather(temp: maxTemp, feels_like: maxTemp, humidity: 50),
                    weather: [WeatherCondition(main: weatherCodeToCondition(weatherCode), 
                                             description: weatherCodeToDescription(weatherCode), 
                                             icon: "")],
                    dt_txt: dateString
                )
            }
        }
    }
    

}

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeatherForLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location access failed"
            self.currentWeather = nil
            self.forecast = []
            self.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            fetchWeather()
        case .denied, .restricted:
            errorMessage = "Location access denied"
            currentWeather = nil
            forecast = []
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// Calendar data models
struct CalendarEventData {
    let title: String
    let startDate: Date
    let isAllDay: Bool
}

class CalendarService: ObservableObject {
    @Published var upcomingEvents: [CalendarEventData] = []
    private let eventStore = EKEventStore()
    
    init() {
        requestCalendarAccess()
    }
    
    private func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if granted {
                self?.fetchUpcomingEvents()
            } else {
                // Load mock events for demo
                DispatchQueue.main.async {
    
                }
            }
        }
    }
    
    private func fetchUpcomingEvents() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.upcomingEvents = events.prefix(3).map { event in
                CalendarEventData(
                    title: event.title,
                    startDate: event.startDate,
                    isAllDay: event.isAllDay
                )
            }
        }
    }
    

}

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var brightness: Double = 0.8
    @State private var isNightMode = false
    @State private var isAutoNightMode = true
    @State private var showSettings = false
    @State private var is24HourFormat = false
    @State private var showSeconds = true
    @State private var showDate = true
    @State private var showWeather = true
    @State private var showBattery = true
    @State private var showCalendar = true
    @State private var nightColorTheme: NightColorTheme = .red
    @State private var batteryLevel: Float = 0.0
    @State private var isCharging = false
    @State private var deviceOrientation = UIDeviceOrientation.unknown
    
    @StateObject private var weatherService = WeatherService()
    @StateObject private var calendarService = CalendarService()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundColor(textColor.opacity(0.4))
                        }
                        .padding(.top, 30)
                        .padding(.trailing, 30)
                    }
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { newTime in
            currentTime = newTime
            updateNightMode()
            updateBatteryStatus()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            updateBatteryStatus()
            weatherService.fetchWeather()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            deviceOrientation = UIDevice.current.orientation
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                brightness: $brightness,
                isNightMode: $isNightMode,
                isAutoNightMode: $isAutoNightMode,
                is24HourFormat: $is24HourFormat,
                showSeconds: $showSeconds,
                showDate: $showDate,
                showWeather: $showWeather,
                showBattery: $showBattery,
                showCalendar: $showCalendar,
                nightColorTheme: $nightColorTheme,
                weatherService: weatherService
            )
        }
    }
    
    @ViewBuilder
    private func elegantPortraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main time display - centered and prominent
            VStack(spacing: 16) {
                Text(timeString)
                    .font(.system(
                        size: min(geometry.size.width * 0.18, 80),
                        weight: .ultraLight,
                        design: .rounded
                    ))
                    .foregroundColor(textColor)
                    .monospacedDigit()
                
                if showDate {
                    Text(dateString)
                        .font(.system(size: 18, weight: .light))
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
                        .font(.system(
                            size: min(geometry.size.width * 0.12, 70),
                            weight: .ultraLight,
                            design: .rounded
                        ))
                        .foregroundColor(textColor)
                        .monospacedDigit()
                    
                    if showDate {
                        Text(dateString)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }
                
                // Weather below time
                if showWeather && weatherService.currentWeather != nil {
                    elegantWeatherSection()
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
    
    // Weather forecast section showing current + 7 days
    @ViewBuilder
    private func weatherForecastSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Current weather
            if let current = weatherService.currentWeather {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Now")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.7))
                        
                        HStack(spacing: 8) {
                            Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                                .font(.title2)
                            
                            Text("\(Int(current.main.temp))°")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(textColor)
                        }
                        
                        Text(current.weather.first?.description.capitalized ?? "Clear")
                            .font(.caption2)
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(current.name)
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.7))
                        
                        if weatherService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 7-day forecast
            if !weatherService.forecast.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(weatherService.forecast.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 6) {
                                Text(dayNameForForecast(item, index: index))
                                    .font(.caption2)
                                    .foregroundColor(textColor.opacity(0.7))
                                    .frame(minWidth: 35)
                                
                                Text(weatherIconForCondition(item.weather.first?.main ?? "Clear"))
                                    .font(.title3)
                                
                                Text("\(Int(item.main.temp))°")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor)
                            }
                            .frame(width: 45)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // Current weather section for landscape
    @ViewBuilder
    private func currentWeatherSection() -> some View {
        if let current = weatherService.currentWeather {
            HStack {
                Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(current.main.temp))°")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text(current.weather.first?.description.capitalized ?? "Clear")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.7))
                }
                
                Spacer()
            }
        }
    }
    
    // Helper function to get weather icons
    private func weatherIconForCondition(_ condition: String) -> String {
        switch condition.lowercased() {
        case "clear": return "☀️"
        case "clouds", "partly cloudy": return "⛅"
        case "rain": return "🌧️"
        case "snow": return "❄️"
        case "thunderstorm": return "⛈️"
        case "drizzle": return "🌦️"
        case "mist", "fog": return "🌫️"
        default: return "☀️"
        }
    }
    
    // Helper function to get day names for forecast
    private func dayNameForForecast(_ item: ForecastItem, index: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
        let formatter = DateFormatter()
        
        if index == 0 {
            return "Today"
        } else if index == 1 {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        }
    }
    
    @ViewBuilder
    private func compactTimeDisplay(geometry: GeometryProxy) -> some View {
        Text(timeString)
            .font(.system(
                size: min(geometry.size.width * 0.12, 60),
                weight: .thin,
                design: .rounded
            ))
            .foregroundColor(textColor)
            .monospacedDigit()
    }
    
    @ViewBuilder
    private func mainTimeDisplay(geometry: GeometryProxy, isLandscape: Bool) -> some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.system(
                    size: isLandscape ? 
                        min(geometry.size.width * 0.08, 70) : 
                        min(geometry.size.width * 0.15, 120), 
                    weight: .thin, 
                    design: .rounded
                ))
                .foregroundColor(textColor)
                .monospacedDigit()
            
            if showDate {
                Text(dateString)
                    .font(.system(
                        size: isLandscape ? 
                            min(geometry.size.width * 0.025, 20) : 
                            min(geometry.size.width * 0.04, 24), 
                        weight: .light
                    ))
                    .foregroundColor(textColor.opacity(0.8))
            }
        }
    }
    
    @ViewBuilder
    private func calendarGridView(geometry: GeometryProxy) -> some View {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        let currentDay = calendar.component(.day, from: today)
        
        // Get first day of month and number of days
        let firstOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        
        VStack(spacing: 8) {
            // Month and year header
            Text(DateFormatter().monthSymbols[currentMonth - 1] + " " + String(currentYear))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let totalCells = 42 // 6 rows × 7 days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<totalCells, id: \.self) { index in
                    let dayNumber = index - firstWeekday + 1
                    
                    if dayNumber > 0 && dayNumber <= daysInMonth {
                        Text("\(dayNumber)")
                            .font(.caption)
                            .foregroundColor(dayNumber == currentDay ? .black : textColor)
                            .frame(width: 24, height: 24)
                            .background(
                                dayNumber == currentDay ? 
                                    Circle().fill(textColor) : 
                                    Circle().fill(Color.clear)
                            )
                    } else {
                        Text("")
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .padding(12)
    }
    
    @ViewBuilder
    private func calendarEventsSection() -> some View {
        if !calendarService.upcomingEvents.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming")
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.7))
                    .padding(.horizontal, 30)
                
                ForEach(calendarService.upcomingEvents.indices, id: \.self) { index in
                    let event = calendarService.upcomingEvents[index]
                    HStack {
                        Circle()
                            .fill(textColor.opacity(0.6))
                            .frame(width: 4, height: 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.caption)
                                .foregroundColor(textColor)
                                .lineLimit(1)
                            
                            Text(eventTimeString(for: event))
                                .font(.caption2)
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
    
    @ViewBuilder
    private func batterySection() -> some View {
        HStack {
            Image(systemName: isCharging ? "battery.100.bolt" : "battery.100")
                .foregroundColor(batteryColor)
                .font(.caption)
            
            Text("\(Int(batteryLevel * 100))%")
                .font(.caption)
                .foregroundColor(textColor.opacity(0.7))
            
            if isCharging {
                Text("Charging")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.5))
            }
        }
    }
    
    @ViewBuilder
    private func topInfoBar() -> some View {
        HStack {
            if showBattery {
                batterySection()
            }
            
            Spacer()
            
            if showWeather, let weather = weatherService.currentWeather {
                HStack {
                    Text(weatherIconForCondition(weather.weather.first?.main ?? "Clear"))
                        .font(.caption)
                    Text("\(Int(weather.main.temp))°")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private func bottomControls() -> some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                Slider(value: $brightness, in: 0.1...1.0)
                    .frame(width: 100)
                    .accentColor(textColor)
                
                Text("Brightness")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.bottom, 30)
    }
    
    // Computed properties
    private var backgroundColor: Color {
        Color.black.opacity(brightness)
    }
    
    private var textColor: Color {
        if isNightMode {
            return nightColorTheme.color
        } else {
            return Color.white
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel < 0.2 {
            return Color.red
        } else if batteryLevel < 0.5 {
            return Color.orange
        } else {
            return textColor.opacity(0.7)
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
    
    private func eventTimeString(for event: CalendarEventData) -> String {
        if event.isAllDay {
            return "All day"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") // Force consistent formatting
            formatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"
            return formatter.string(from: event.startDate)
        }
    }
    
    private func updateNightMode() {
        // Only update night mode automatically if it's in auto mode
        guard isAutoNightMode else { return }
        
        let hour = Calendar.current.component(.hour, from: currentTime)
        // Auto night mode between 9 PM and 7 AM
        let shouldBeNightMode = hour >= 21 || hour < 7
        if shouldBeNightMode != isNightMode {
            withAnimation(.easeInOut(duration: 2.0)) {
                isNightMode = shouldBeNightMode
            }
        }
    }
    
    private func updateBatteryStatus() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    // MARK: - Elegant Component Functions
    
    @ViewBuilder
    private func elegantWeatherSection() -> some View {
        if let current = weatherService.currentWeather {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(weatherIconForCondition(current.weather.first?.main ?? "Clear"))
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(current.main.temp))°")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text(current.weather.first?.description.capitalized ?? "Clear")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
                
                if let cityName = weatherService.selectedCity?.name {
                    Text(cityName)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.5))
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.8))
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
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
                            .font(.system(size: 11))
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
                        .font(.system(size: 12))
                        .foregroundColor(batteryColor.opacity(0.8))
                    
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Brightness control
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .font(.system(size: 10))
                    .foregroundColor(textColor.opacity(0.4))
                
                Slider(value: $brightness, in: 0.1...1.0)
                    .frame(width: 80)
                    .accentColor(textColor.opacity(0.6))
                
                Image(systemName: "sun.max")
                    .font(.system(size: 10))
                    .foregroundColor(textColor.opacity(0.4))
            }
        }
    }
}

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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Display Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Display")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Brightness")
                                Spacer()
                                Slider(value: $brightness, in: 0.1...1.0)
                                    .frame(width: 120)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Night Mode", isOn: $isNightMode)
                                    .padding(.horizontal, 20)
                                
                                if !isAutoNightMode {
                                    Toggle("Auto Night Mode", isOn: $isAutoNightMode)
                                        .padding(.horizontal, 20)
                                        .onChange(of: isAutoNightMode) { 
                                            // When turning off auto mode, keep current manual state
                                        }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle("24 Hour Format", isOn: $is24HourFormat)
                                Text("Current: \(is24HourFormat ? "24-hour" : "12-hour") format")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            Toggle("Show Seconds", isOn: $showSeconds)
                                .padding(.horizontal, 20)
                            
                            Toggle("Show Date", isOn: $showDate)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Weather Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weather")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Toggle("Show Weather", isOn: $showWeather)
                                .padding(.horizontal, 20)
                            
                            if showWeather {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Location")
                                            .font(.subheadline)
                                        Spacer()
                                        Button(weatherService.selectedCity?.displayName ?? "Current Location") {
                                            // This would show city picker
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // City selection
                                    Text("Choose City:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            // Current location option
                                            Button("Current Location") {
                                                weatherService.selectCity(nil)
                                            }
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(weatherService.selectedCity == nil ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            
                                            ForEach(weatherService.availableCities, id: \.id) { city in
                                                Button(city.displayName) {
                                                    weatherService.selectCity(city)
                                                }
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(weatherService.selectedCity == city ? Color.blue : Color.gray.opacity(0.3))
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    Button("Refresh Weather") {
                                        weatherService.fetchWeather()
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 20)
                                    
                                    if let errorMessage = weatherService.errorMessage {
                                        Text("Error: \(errorMessage)")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 20)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Night Mode Theme
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Night Mode Theme")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(NightColorTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    nightColorTheme = theme
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 20, height: 20)
                                        
                                        Text(theme.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if nightColorTheme == theme {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Toggle("Battery Status", isOn: $showBattery)
                                .padding(.horizontal, 20)
                            
                            Toggle("Calendar", isOn: $showCalendar)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Weather API Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weather Information")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        Text("Weather data is provided by Open-Meteo, a free weather API that doesn't require an API key. The app automatically fetches real weather data for your selected location.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
