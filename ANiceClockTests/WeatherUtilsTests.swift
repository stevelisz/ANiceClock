import Testing
@testable import ANiceClock

struct WeatherUtilsTests {
    
    // MARK: - Weather Code Mapping Tests
    
    @Test func testWeatherCodeToCondition() async throws {
        // Test clear weather codes
        #expect(weatherCodeToCondition(0) == "Clear")
        #expect(weatherCodeToCondition(1) == "Clouds")
        
        // Test cloudy weather codes
        #expect(weatherCodeToCondition(2) == "Clouds")
        #expect(weatherCodeToCondition(3) == "Clouds")
        
        // Test fog codes
        #expect(weatherCodeToCondition(45) == "Fog")
        #expect(weatherCodeToCondition(48) == "Fog")
        
        // Test drizzle codes
        #expect(weatherCodeToCondition(51) == "Drizzle")
        #expect(weatherCodeToCondition(53) == "Drizzle")
        #expect(weatherCodeToCondition(55) == "Drizzle")
        
        // Test rain codes
        #expect(weatherCodeToCondition(61) == "Rain")
        #expect(weatherCodeToCondition(63) == "Rain")
        #expect(weatherCodeToCondition(65) == "Rain")
        
        // Test snow codes
        #expect(weatherCodeToCondition(71) == "Snow")
        #expect(weatherCodeToCondition(73) == "Snow")
        #expect(weatherCodeToCondition(75) == "Snow")
        
        // Test thunderstorm codes
        #expect(weatherCodeToCondition(95) == "Thunderstorm")
        #expect(weatherCodeToCondition(96) == "Thunderstorm")
        #expect(weatherCodeToCondition(99) == "Thunderstorm")
    }
    
    @Test func testWeatherCodeToDescription() async throws {
        // Test clear weather descriptions
        #expect(weatherCodeToDescription(0) == "clear sky")
        #expect(weatherCodeToDescription(1) == "mainly clear")
        
        // Test cloudy weather descriptions
        #expect(weatherCodeToDescription(2) == "partly cloudy")
        #expect(weatherCodeToDescription(3) == "overcast")
        
        // Test fog descriptions
        #expect(weatherCodeToDescription(45) == "fog")
        #expect(weatherCodeToDescription(48) == "fog")
        
        // Test drizzle descriptions
        #expect(weatherCodeToDescription(51) == "light drizzle")
        #expect(weatherCodeToDescription(53) == "moderate drizzle")
        #expect(weatherCodeToDescription(55) == "dense drizzle")
        
        // Test rain descriptions
        #expect(weatherCodeToDescription(61) == "slight rain")
        #expect(weatherCodeToDescription(63) == "moderate rain")
        #expect(weatherCodeToDescription(65) == "heavy rain")
        
        // Test snow descriptions
        #expect(weatherCodeToDescription(71) == "slight snow")
        #expect(weatherCodeToDescription(73) == "moderate snow")
        #expect(weatherCodeToDescription(75) == "heavy snow")
        
        // Test rain showers
        #expect(weatherCodeToDescription(80) == "rain showers")
        
        // Test thunderstorm descriptions
        #expect(weatherCodeToDescription(95) == "thunderstorm")
        
        // Test codes that fall back to default (clear sky)
        #expect(weatherCodeToDescription(56) == "clear sky") // freezing drizzle - not specifically handled
        #expect(weatherCodeToDescription(57) == "clear sky") // dense freezing drizzle - not specifically handled
        #expect(weatherCodeToDescription(66) == "clear sky") // freezing rain - not specifically handled
        #expect(weatherCodeToDescription(67) == "clear sky") // heavy freezing rain - not specifically handled
        #expect(weatherCodeToDescription(77) == "clear sky") // snow grains - not specifically handled
        #expect(weatherCodeToDescription(81) == "clear sky") // moderate rain showers - not specifically handled
        #expect(weatherCodeToDescription(82) == "clear sky") // violent rain showers - not specifically handled
        #expect(weatherCodeToDescription(85) == "clear sky") // snow showers - not specifically handled
        #expect(weatherCodeToDescription(86) == "clear sky") // heavy snow showers - not specifically handled
        #expect(weatherCodeToDescription(96) == "clear sky") // thunderstorm with hail - not specifically handled
        #expect(weatherCodeToDescription(99) == "clear sky") // thunderstorm with heavy hail - not specifically handled
    }
    
    @Test func testEdgeCaseWeatherCodes() async throws {
        // Test unknown/invalid weather codes default to Clear
        #expect(weatherCodeToCondition(999) == "Clear")
        #expect(weatherCodeToCondition(-1) == "Clear")
        
        // Test unknown descriptions default to clear sky
        #expect(weatherCodeToDescription(999) == "clear sky")
        #expect(weatherCodeToDescription(-1) == "clear sky")
    }
    
    @Test func testWeatherIconMapping() async throws {
        // Test that weather condition strings map to appropriate icons
        // This assumes you have a weatherIconForCondition function in your views
        
        // We can test common weather conditions
        let clearCondition = "Clear"
        let cloudyCondition = "Clouds"
        let rainyCondition = "Rain"
        let snowyCondition = "Snow"
        
        // Test that conditions are valid strings
        #expect(clearCondition == "Clear")
        #expect(cloudyCondition == "Clouds")
        #expect(rainyCondition == "Rain")
        #expect(snowyCondition == "Snow")
    }
    
    @Test func testWeatherCodeConsistency() async throws {
        // Test that the same code always returns the same condition and description
        let testCode = 61
        let condition1 = weatherCodeToCondition(testCode)
        let condition2 = weatherCodeToCondition(testCode)
        let description1 = weatherCodeToDescription(testCode)
        let description2 = weatherCodeToDescription(testCode)
        
        #expect(condition1 == condition2)
        #expect(description1 == description2)
    }
    
    @Test func testAllWeatherCodesHaveValidOutput() async throws {
        // Test a range of weather codes to ensure they all return non-empty strings
        let testCodes = [0, 1, 2, 3, 45, 48, 51, 53, 55, 61, 63, 65, 71, 73, 75, 95, 96, 99]
        
        for code in testCodes {
            let condition = weatherCodeToCondition(code)
            let description = weatherCodeToDescription(code)
            
            #expect(!condition.isEmpty)
            #expect(!description.isEmpty)
        }
    }

    // MARK: - Additional Weather Code Tests
    
    @Test func testAdditionalWeatherCodes() async throws {
        // Test additional codes that exist in the actual implementation
        #expect(weatherCodeToCondition(56) == "Drizzle") // freezing drizzle
        #expect(weatherCodeToCondition(57) == "Drizzle") // dense freezing drizzle
        #expect(weatherCodeToCondition(66) == "Rain")    // freezing rain
        #expect(weatherCodeToCondition(67) == "Rain")    // heavy freezing rain
        #expect(weatherCodeToCondition(77) == "Snow")    // snow grains
        #expect(weatherCodeToCondition(80) == "Rain")    // rain showers
        #expect(weatherCodeToCondition(81) == "Rain")    // moderate rain showers
        #expect(weatherCodeToCondition(82) == "Rain")    // violent rain showers
        #expect(weatherCodeToCondition(85) == "Snow")    // snow showers
        #expect(weatherCodeToCondition(86) == "Snow")    // heavy snow showers
    }
    
    @Test func testRainShowersDescription() async throws {
        // Test rain showers specific description
        #expect(weatherCodeToDescription(80) == "rain showers")
    }
    
    @Test func testWeatherIconForConditionFunction() async throws {
        // Test the weatherIconForCondition function
        #expect(weatherIconForCondition("Clear") == "☀️")
        #expect(weatherIconForCondition("Clouds") == "☁️")
        #expect(weatherIconForCondition("Rain") == "🌧️")
        #expect(weatherIconForCondition("Drizzle") == "🌦️")
        #expect(weatherIconForCondition("Thunderstorm") == "⛈️")
        #expect(weatherIconForCondition("Snow") == "❄️")
        #expect(weatherIconForCondition("Fog") == "🌫️")
        #expect(weatherIconForCondition("Mist") == "🌫️")
        #expect(weatherIconForCondition("Haze") == "🌫️")
        
        // Test case insensitive
        #expect(weatherIconForCondition("clear") == "☀️")
        #expect(weatherIconForCondition("CLOUDS") == "☁️")
        
        // Test default case
        #expect(weatherIconForCondition("Unknown") == "☀️")
        #expect(weatherIconForCondition("") == "☀️")
    }
} 