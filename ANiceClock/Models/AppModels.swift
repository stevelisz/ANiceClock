import SwiftUI
import CoreLocation
import Photos

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

// Calendar data models
struct CalendarEventData {
    let title: String
    let startDate: Date
    let isAllDay: Bool
}

// View Mode Enum
enum ViewMode: String, CaseIterable {
    case clock = "Clock"
    case gallery = "Gallery"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Gallery Photo Model
// Pure native approach - just store PHAsset IDs
struct GalleryPhoto: Identifiable, Codable {
    let id: String // PHAsset.localIdentifier
    
    init(assetID: String) {
        self.id = assetID
    }
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
    }
    
    // Helper to get PHAsset when needed (on-demand)
    var asset: PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return fetchResult.firstObject
    }
} 