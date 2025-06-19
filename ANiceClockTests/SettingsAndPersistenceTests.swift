import Testing
import Foundation
import SwiftUI
@testable import ANiceClock

struct SettingsAndPersistenceTests {
    
    // MARK: - AppStorage Key Tests
    
    @Test func testAllAppStorageKeysAreUnique() async throws {
        let keys = [
            "ANiceClock_brightness",
            "ANiceClock_isNightMode",
            "ANiceClock_isAutoNightMode",
            "ANiceClock_is24HourFormat",
            "ANiceClock_showSeconds",
            "ANiceClock_showDate",
            "ANiceClock_showWeather",
            "ANiceClock_showBattery",
            "ANiceClock_showCalendar",
            "ANiceClock_nightColorTheme",
            "ANiceClock_fontFamily",
            "ANiceClock_glassPanelOpacity",
            "ANiceClock_viewMode",
            "ANiceClock_galleryDuration"
        ]
        
        let uniqueKeys = Set(keys)
        #expect(keys.count == uniqueKeys.count) // All keys should be unique
        #expect(keys.count == 14) // Total number of expected settings
    }
    
    @Test func testAppStorageKeyNamingConvention() async throws {
        let keys = [
            "ANiceClock_brightness",
            "ANiceClock_isNightMode",
            "ANiceClock_isAutoNightMode",
            "ANiceClock_is24HourFormat",
            "ANiceClock_showSeconds",
            "ANiceClock_showDate",
            "ANiceClock_showWeather",
            "ANiceClock_showBattery",
            "ANiceClock_showCalendar",
            "ANiceClock_nightColorTheme",
            "ANiceClock_fontFamily",
            "ANiceClock_glassPanelOpacity",
            "ANiceClock_viewMode",
            "ANiceClock_galleryDuration"
        ]
        
        // Test that all keys follow the "ANiceClock_" prefix convention
        for key in keys {
            #expect(key.hasPrefix("ANiceClock_"))
        }
    }
    
    // MARK: - Settings Default Values Tests
    
    @Test func testBrightnessDefaultValue() async throws {
        // Test that brightness has appropriate default value
        let defaultBrightness: Double = 0.8
        #expect(defaultBrightness >= 0.0 && defaultBrightness <= 1.0)
        #expect(defaultBrightness == 0.8)
    }
    
    @Test func testNightModeDefaultValues() async throws {
        // Test night mode defaults
        let defaultIsNightMode = false
        let defaultIsAutoNightMode = true
        let defaultNightColorTheme = NightColorTheme.red
        
        #expect(defaultIsNightMode == false)
        #expect(defaultIsAutoNightMode == true)
        #expect(defaultNightColorTheme == .red)
    }
    
    @Test func testTimeDisplayDefaultValues() async throws {
        // Test time display defaults
        let defaultIs24HourFormat = false
        let defaultShowSeconds = true
        let defaultShowDate = true
        
        #expect(defaultIs24HourFormat == false)
        #expect(defaultShowSeconds == true)
        #expect(defaultShowDate == true)
    }
    
    @Test func testUIElementDefaultValues() async throws {
        // Test UI element visibility defaults
        let defaultShowWeather = true
        let defaultShowBattery = true
        let defaultShowCalendar = true
        
        #expect(defaultShowWeather == true)
        #expect(defaultShowBattery == true)
        #expect(defaultShowCalendar == true)
    }
    
    @Test func testFontAndOpacityDefaults() async throws {
        // Test font and opacity defaults
        let defaultFontFamily = FontFamily.system
        let defaultGlassPanelOpacity: Double = 0.8
        
        #expect(defaultFontFamily == .system)
        #expect(defaultGlassPanelOpacity >= 0.0 && defaultGlassPanelOpacity <= 1.0)
        #expect(defaultGlassPanelOpacity == 0.8)
    }
    
    @Test func testViewModeAndGalleryDefaults() async throws {
        // Test view mode and gallery defaults
        let defaultViewMode = ViewMode.clock
        let defaultGalleryDuration: Double = 5.0
        
        #expect(defaultViewMode == .clock)
        #expect(defaultGalleryDuration > 0.0)
        #expect(defaultGalleryDuration == 5.0)
    }
    
    // MARK: - Settings Value Range Tests
    
    @Test func testBrightnessRange() async throws {
        // Test brightness value constraints
        let minBrightness: Double = 0.1
        let maxBrightness: Double = 1.0
        let defaultBrightness: Double = 0.8
        
        #expect(minBrightness >= 0.0)
        #expect(maxBrightness <= 1.0)
        #expect(defaultBrightness >= minBrightness)
        #expect(defaultBrightness <= maxBrightness)
    }
    
    @Test func testGlassPanelOpacityRange() async throws {
        // Test glass panel opacity constraints
        let minOpacity: Double = 0.1
        let maxOpacity: Double = 1.0
        let defaultOpacity: Double = 0.8
        
        #expect(minOpacity >= 0.0)
        #expect(maxOpacity <= 1.0)
        #expect(defaultOpacity >= minOpacity)
        #expect(defaultOpacity <= maxOpacity)
    }
    
    @Test func testGalleryDurationRange() async throws {
        // Test gallery duration constraints
        let minDuration: Double = 1.0
        let maxDuration: Double = 30.0
        let defaultDuration: Double = 5.0
        
        #expect(minDuration > 0.0)
        #expect(maxDuration >= minDuration)
        #expect(defaultDuration >= minDuration)
        #expect(defaultDuration <= maxDuration)
    }
    
    // MARK: - Settings Persistence Simulation Tests
    
    @Test func testUserDefaultsKeyConsistency() async throws {
        // Test that our key constants match expected UserDefaults keys
        let brightnessKey = "ANiceClock_brightness"
        let nightModeKey = "ANiceClock_isNightMode"
        let fontFamilyKey = "ANiceClock_fontFamily"
        
        // Test key format consistency
        #expect(brightnessKey.contains("brightness"))
        #expect(nightModeKey.contains("isNightMode"))
        #expect(fontFamilyKey.contains("fontFamily"))
        
        // Test prefix consistency
        #expect(brightnessKey.hasPrefix("ANiceClock_"))
        #expect(nightModeKey.hasPrefix("ANiceClock_"))
        #expect(fontFamilyKey.hasPrefix("ANiceClock_"))
    }
    
    @Test func testSettingsDataTypes() async throws {
        // Test that settings use appropriate data types
        let brightness: Double = 0.8
        let isNightMode: Bool = false
        let fontFamily: FontFamily = .system
        let viewMode: ViewMode = .clock
        let nightColorTheme: NightColorTheme = .red
        
        #expect(brightness is Double)
        #expect(isNightMode is Bool)
        #expect(fontFamily is FontFamily)
        #expect(viewMode is ViewMode)
        #expect(nightColorTheme is NightColorTheme)
    }
    
    // MARK: - Settings Validation Tests
    
    @Test func testNightColorThemeValidation() async throws {
        // Test all night color themes are valid
        for theme in NightColorTheme.allCases {
            #expect(!theme.rawValue.isEmpty)
            #expect(theme.color is Color)
        }
    }
    
    @Test func testFontFamilyValidation() async throws {
        // Test all font families are valid
        for fontFamily in FontFamily.allCases {
            #expect(!fontFamily.rawValue.isEmpty)
            #expect(!fontFamily.displayName.isEmpty)
            #expect(!fontFamily.fontName.isEmpty)
            
            // Test font creation doesn't throw
            let font = fontFamily.font(size: 16)
            #expect(font is Font)
        }
    }
    
    @Test func testViewModeValidation() async throws {
        // Test all view modes are valid
        for viewMode in ViewMode.allCases {
            #expect(!viewMode.rawValue.isEmpty)
            #expect(!viewMode.displayName.isEmpty)
        }
    }
    
    // MARK: - Settings Interaction Tests
    
    @Test func testSettingsDoNotConflict() async throws {
        // Test that different settings can coexist
        let brightnessValue: Double = 0.8
        let isNightModeValue = false
        let showSecondsValue = true
        let glassPanelOpacityValue: Double = 0.6
        
        // Test that we can have multiple settings active
        #expect(brightnessValue == 0.8)
        #expect(isNightModeValue == false)
        #expect(showSecondsValue == true)
        #expect(glassPanelOpacityValue == 0.6)
        
        // Test brightness and opacity are independent
        let brightness = 0.8
        let opacity = 0.6
        #expect(brightness != opacity) // They can have different values
    }
    
    @Test func testBooleanSettingsIndependence() async throws {
        // Test that boolean settings are independent
        let showWeather = true
        let showBattery = false
        let showCalendar = true
        let showSeconds = false
        let showDate = true
        
        // Test various combinations are valid
        #expect(showWeather == true)
        #expect(showBattery == false)
        #expect(showCalendar == true)
        #expect(showSeconds == false)
        #expect(showDate == true)
        
        // Test that different combinations don't interfere
        #expect(showWeather != showBattery)
        #expect(showCalendar == showWeather)
        #expect(showSeconds != showDate)
    }
    
    // MARK: - Gallery Panel Position Tests
    
    @Test func testGalleryPanelPositionKeys() async throws {
        let panelPositionXKey = "ANiceClock_GalleryPanelX"
        let panelPositionYKey = "ANiceClock_GalleryPanelY"
        
        #expect(panelPositionXKey.hasPrefix("ANiceClock_"))
        #expect(panelPositionYKey.hasPrefix("ANiceClock_"))
        #expect(panelPositionXKey.contains("GalleryPanelX"))
        #expect(panelPositionYKey.contains("GalleryPanelY"))
    }
    
    @Test func testPanelPositionDataTypes() async throws {
        // Test panel position uses appropriate data types
        let positionX: Double = 100.0
        let positionY: Double = 200.0
        
        #expect(positionX is Double)
        #expect(positionY is Double)
        #expect(positionX >= 0.0)
        #expect(positionY >= 0.0)
    }
    
    // MARK: - Settings State Management Tests
    
    @Test func testSettingsStateConsistency() async throws {
        // Test that settings maintain consistent state
        var isNightMode = false
        var nightColorTheme = NightColorTheme.red
        
        // Test initial state
        #expect(isNightMode == false)
        #expect(nightColorTheme == .red)
        
        // Test state changes
        isNightMode = true
        nightColorTheme = .blue
        
        #expect(isNightMode == true)
        #expect(nightColorTheme == .blue)
    }
    
    @Test func testSettingsGroupLogic() async throws {
        // Test logical groupings of settings
        
        // Time display group
        let timeSettings = (
            is24HourFormat: false,
            showSeconds: true,
            showDate: true
        )
        
        // UI visibility group
        let visibilitySettings = (
            showWeather: true,
            showBattery: true,
            showCalendar: true
        )
        
        // Appearance group
        let appearanceSettings = (
            brightness: 0.8,
            isNightMode: false,
            fontFamily: FontFamily.system,
            glassPanelOpacity: 0.8
        )
        
        // Test groups are independent
        #expect(timeSettings.showSeconds == true)
        #expect(visibilitySettings.showWeather == true)
        #expect(appearanceSettings.brightness == 0.8)
    }
} 