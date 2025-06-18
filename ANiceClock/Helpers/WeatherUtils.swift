import Foundation

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

func weatherIconForCondition(_ condition: String) -> String {
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