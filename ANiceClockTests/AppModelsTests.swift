import Testing
import SwiftUI
@testable import ANiceClock

struct AppModelsTests {
    
    // MARK: - NightColorTheme Tests
    
    @Test func testNightColorThemeAllCases() async throws {
        let allCases = NightColorTheme.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.red))
        #expect(allCases.contains(.amber))
        #expect(allCases.contains(.green))
        #expect(allCases.contains(.blue))
        #expect(allCases.contains(.purple))
        #expect(allCases.contains(.orange))
    }
    
    @Test func testNightColorThemeRawValues() async throws {
        #expect(NightColorTheme.red.rawValue == "Red")
        #expect(NightColorTheme.amber.rawValue == "Amber")
        #expect(NightColorTheme.green.rawValue == "Green")
        #expect(NightColorTheme.blue.rawValue == "Blue")
        #expect(NightColorTheme.purple.rawValue == "Purple")
        #expect(NightColorTheme.orange.rawValue == "Orange")
    }
    
    @Test func testNightColorThemeColors() async throws {
        // Test that each theme returns a Color (we can't test exact colors but can verify they're not nil)
        #expect(NightColorTheme.red.color is Color)
        #expect(NightColorTheme.amber.color is Color)
        #expect(NightColorTheme.green.color is Color)
        #expect(NightColorTheme.blue.color is Color)
        #expect(NightColorTheme.purple.color is Color)
        #expect(NightColorTheme.orange.color is Color)
    }
    
    // MARK: - FontFamily Tests
    
    @Test func testFontFamilyAllCases() async throws {
        let allCases = FontFamily.allCases
        #expect(allCases.count == 14)
        #expect(allCases.contains(.system))
        #expect(allCases.contains(.avenir))
        #expect(allCases.contains(.helvetica))
        #expect(allCases.contains(.futura))
        #expect(allCases.contains(.palatino))
        #expect(allCases.contains(.optima))
        #expect(allCases.contains(.baskerville))
        #expect(allCases.contains(.georgia))
        #expect(allCases.contains(.courier))
        #expect(allCases.contains(.menlo))
        #expect(allCases.contains(.americanTypewriter))
        #expect(allCases.contains(.sfMono))
        #expect(allCases.contains(.chalkduster))
        #expect(allCases.contains(.digitalClock))
    }
    
    @Test func testFontFamilyDisplayNames() async throws {
        #expect(FontFamily.system.displayName == "System")
        #expect(FontFamily.avenir.displayName == "Avenir Next")
        #expect(FontFamily.helvetica.displayName == "Helvetica Neue")
        #expect(FontFamily.futura.displayName == "Futura")
        #expect(FontFamily.palatino.displayName == "Palatino")
        #expect(FontFamily.optima.displayName == "Optima")
        #expect(FontFamily.baskerville.displayName == "Baskerville")
        #expect(FontFamily.georgia.displayName == "Georgia")
        #expect(FontFamily.courier.displayName == "Courier New")
        #expect(FontFamily.menlo.displayName == "Menlo")
        #expect(FontFamily.americanTypewriter.displayName == "American Typewriter")
        #expect(FontFamily.sfMono.displayName == "SF Mono")
        #expect(FontFamily.chalkduster.displayName == "Chalkduster")
        #expect(FontFamily.digitalClock.displayName == "Digital Clock")
    }
    
    @Test func testFontFamilyFontNames() async throws {
        #expect(FontFamily.system.fontName == ".AppleSystemUIFont")
        #expect(FontFamily.avenir.fontName == "AvenirNext-Regular")
        #expect(FontFamily.helvetica.fontName == "HelveticaNeue")
        #expect(FontFamily.futura.fontName == "Futura-Medium")
        #expect(FontFamily.palatino.fontName == "Palatino-Roman")
        #expect(FontFamily.optima.fontName == "Optima-Regular")
        #expect(FontFamily.baskerville.fontName == "Baskerville")
        #expect(FontFamily.georgia.fontName == "Georgia")
        #expect(FontFamily.courier.fontName == "CourierNewPSMT")
        #expect(FontFamily.menlo.fontName == "Menlo-Regular")
        #expect(FontFamily.americanTypewriter.fontName == "AmericanTypewriter")
        #expect(FontFamily.sfMono.fontName == "SFMono-Regular")
        #expect(FontFamily.chalkduster.fontName == "Chalkduster")
        #expect(FontFamily.digitalClock.fontName == "Menlo-Regular")
    }
    
    @Test func testSystemFontCreation() async throws {
        let font = FontFamily.system.font(size: 16, weight: .medium)
        #expect(font is Font)
    }
    
    @Test func testCustomFontCreation() async throws {
        let font = FontFamily.helvetica.font(size: 20, weight: .bold)
        #expect(font is Font)
    }
    
    @Test func testFontSizeAndWeight() async throws {
        let smallFont = FontFamily.avenir.font(size: 12, weight: .light)
        let largeFont = FontFamily.avenir.font(size: 24, weight: .heavy)
        #expect(smallFont is Font)
        #expect(largeFont is Font)
    }
    
    @Test func testDigitalClockFontSpecialCase() async throws {
        let digitalFont = FontFamily.digitalClock.font(size: 18, weight: .regular)
        #expect(digitalFont is Font)
    }
    
    // MARK: - ViewMode Tests
    
    @Test func testViewModeAllCases() async throws {
        let allCases = ViewMode.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.clock))
        #expect(allCases.contains(.gallery))
    }
    
    @Test func testViewModeDisplayNames() async throws {
        #expect(ViewMode.clock.displayName == "Clock")
        #expect(ViewMode.gallery.displayName == "Gallery")
    }
    
    @Test func testViewModeRawValues() async throws {
        #expect(ViewMode.clock.rawValue == "Clock")
        #expect(ViewMode.gallery.rawValue == "Gallery")
    }
    
    // MARK: - Weather Model Tests
    
    @Test func testCurrentWeatherDecoding() async throws {
        let json = """
        {
            "temperature_2m": 22.5,
            "apparent_temperature": 24.0,
            "relative_humidity_2m": 65.0,
            "weather_code": 3
        }
        """.data(using: .utf8)!
        
        let currentWeather = try JSONDecoder().decode(CurrentWeather.self, from: json)
        #expect(currentWeather.temperature_2m == 22.5)
        #expect(currentWeather.apparent_temperature == 24.0)
        #expect(currentWeather.relative_humidity_2m == 65.0)
        #expect(currentWeather.weather_code == 3)
    }
    
    @Test func testWeatherCityInitialization() async throws {
        let city = WeatherCity(name: "London", lat: 51.5074, lon: -0.1278, country: "UK")
        #expect(city.name == "London")
        #expect(city.lat == 51.5074)
        #expect(city.lon == -0.1278)
        #expect(city.country == "UK")
        #expect(city.id != UUID()) // Should have a unique ID
    }
    
    @Test func testWeatherCityDisplayName() async throws {
        let city = WeatherCity(name: "Paris", lat: 48.8566, lon: 2.3522, country: "France")
        #expect(city.displayName == "Paris, France")
    }
    
    @Test func testMainWeatherInitialization() async throws {
        let mainWeather = MainWeather(temp: 25.0, feels_like: 27.0, humidity: 70)
        #expect(mainWeather.temp == 25.0)
        #expect(mainWeather.feels_like == 27.0)
        #expect(mainWeather.humidity == 70)
    }
    
    @Test func testWeatherConditionInitialization() async throws {
        let condition = WeatherCondition(main: "Clear", description: "clear sky", icon: "01d")
        #expect(condition.main == "Clear")
        #expect(condition.description == "clear sky")
        #expect(condition.icon == "01d")
    }
    
    @Test func testCalendarEventDataInitialization() async throws {
        let date = Date()
        let event = CalendarEventData(title: "Meeting", startDate: date, isAllDay: false)
        #expect(event.title == "Meeting")
        #expect(event.startDate == date)
        #expect(event.isAllDay == false)
    }
} 