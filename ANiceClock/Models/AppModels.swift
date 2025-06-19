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

// Font Family Enum
enum FontFamily: String, CaseIterable {
    case system = "System"
    case avenir = "Avenir Next"
    case helvetica = "Helvetica Neue"
    case futura = "Futura"
    case palatino = "Palatino"
    case optima = "Optima"
    case baskerville = "Baskerville"
    case georgia = "Georgia"
    case courier = "Courier New"
    case menlo = "Menlo"
    case americanTypewriter = "American Typewriter"
    case sfMono = "SF Mono"
    case chalkduster = "Chalkduster"
    case digitalClock = "Digital Clock"
    
    var displayName: String {
        return self.rawValue
    }
    
    var fontName: String {
        switch self {
        case .system: return ".AppleSystemUIFont"
        case .avenir: return "AvenirNext-Regular"
        case .helvetica: return "HelveticaNeue"
        case .futura: return "Futura-Medium"
        case .palatino: return "Palatino-Roman"
        case .optima: return "Optima-Regular"
        case .baskerville: return "Baskerville"
        case .georgia: return "Georgia"
        case .courier: return "CourierNewPSMT"
        case .menlo: return "Menlo-Regular"
        case .americanTypewriter: return "AmericanTypewriter"
        case .sfMono: return "SFMono-Regular"
        case .chalkduster: return "Chalkduster"
        case .digitalClock: return "Menlo-Regular" // We'll override this with custom styling
        }
    }
    
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: weight, design: .default)
        case .digitalClock:
            // Create a digital clock effect using monospaced font with heavy weight
            return .system(size: size, weight: .black, design: .monospaced)
        default:
            return .custom(fontName, size: size)
        }
    }
}

// Digital Clock Text Modifier for LED/LCD effect
struct DigitalClockTextModifier: ViewModifier {
    let fontFamily: FontFamily
    let size: CGFloat
    let weight: Font.Weight
    let isNightMode: Bool
    
    func body(content: Content) -> some View {
        if fontFamily == .digitalClock {
            content
                .font(.system(size: size, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isNightMode ? Color.red : Color.primary,
                            isNightMode ? Color.red.opacity(0.8) : Color.primary.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: isNightMode ? Color.red.opacity(0.8) : Color.clear,
                    radius: isNightMode ? 8 : 0,
                    x: 0,
                    y: 0
                )
                .shadow(
                    color: isNightMode ? Color.red.opacity(0.4) : Color.clear,
                    radius: isNightMode ? 16 : 0,
                    x: 0,
                    y: 0
                )
                .tracking(2) // Add letter spacing for digital effect
        } else {
            content
                .font(fontFamily.font(size: size, weight: weight))
        }
    }
}

extension View {
    func digitalClockStyle(fontFamily: FontFamily, size: CGFloat, weight: Font.Weight = .regular, isNightMode: Bool = false) -> some View {
        self.modifier(DigitalClockTextModifier(fontFamily: fontFamily, size: size, weight: weight, isNightMode: isNightMode))
    }
} 