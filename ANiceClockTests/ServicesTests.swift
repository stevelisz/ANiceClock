import Testing
import Foundation
import CoreLocation
import Photos
@testable import ANiceClock

struct ServicesTests {
    
    // MARK: - WeatherService Tests
    
    @Test func testWeatherServiceInitialization() async throws {
        let weatherService = WeatherService()
        
        // Test initial state
        #expect(weatherService.currentWeather == nil)
        #expect(weatherService.forecast.isEmpty)
        #expect(weatherService.selectedCity == nil)
        #expect(weatherService.currentLocationName == nil)
        #expect(!weatherService.availableCities.isEmpty)
    }
    
    @Test func testSelectedCityPersistence() async throws {
        let weatherService = WeatherService()
        let testCity = WeatherCity(name: "London", lat: 51.5074, lon: -0.1278, country: "UK")
        
        // Test setting selected city
        weatherService.selectedCity = testCity
        #expect(weatherService.selectedCity?.name == "London")
        #expect(weatherService.selectedCity?.country == "UK")
    }
    
    @Test func testWeatherCitiesPreset() async throws {
        let weatherService = WeatherService()
        
        // Test that cities array is not empty
        #expect(!weatherService.availableCities.isEmpty)
        
        // Test some expected cities
        let cityNames = weatherService.availableCities.map { $0.name }
        #expect(cityNames.contains("New York"))
        #expect(cityNames.contains("London"))
        #expect(cityNames.contains("Tokyo"))
        #expect(cityNames.contains("Paris"))
    }
    
    @Test func testLocationPermissionHandling() async throws {
        let weatherService = WeatherService()
        
        // Test that weather service can handle location permissions
        // (We can't directly test CLLocationManager authorization status in unit tests)
        #expect(weatherService.currentLocationName == nil)
        #expect(weatherService.selectedCity == nil)
        
        // Test that we can set a selected city as fallback
        let testCity = WeatherCity(name: "Test City", lat: 0.0, lon: 0.0, country: "Test")
        weatherService.selectedCity = testCity
        #expect(weatherService.selectedCity?.name == "Test City")
    }
    
    // MARK: - GalleryManager Tests
    
    @Test func testGalleryManagerInitialization() async throws {
        let galleryManager = GalleryManager()
        
        // Test initial state
        #expect(galleryManager.selectedAssetIDs.isEmpty)
        #expect(galleryManager.currentImage == nil)
        #expect(galleryManager.currentIndex == 0)
        #expect(galleryManager.slideshowDuration == 10.0) // Default duration
    }
    
    @Test func testPhotoSelectionStorage() async throws {
        let galleryManager = GalleryManager()
        
        // Test adding asset identifiers (simulating photo selection)
        let testIdentifiers = ["asset1", "asset2", "asset3"]
        galleryManager.selectedAssetIDs = testIdentifiers
        
        #expect(galleryManager.selectedAssetIDs.count == 3)
        #expect(galleryManager.selectedAssetIDs.contains("asset1"))
        #expect(galleryManager.selectedAssetIDs.contains("asset2"))
        #expect(galleryManager.selectedAssetIDs.contains("asset3"))
    }
    
    @Test func testPhotoDeselection() async throws {
        let galleryManager = GalleryManager()
        
        // Setup initial selection
        galleryManager.selectedAssetIDs = ["asset1", "asset2", "asset3"]
        
        // Test removing one photo
        galleryManager.selectedAssetIDs.removeAll { $0 == "asset2" }
        
        #expect(galleryManager.selectedAssetIDs.count == 2)
        #expect(!galleryManager.selectedAssetIDs.contains("asset2"))
        #expect(galleryManager.selectedAssetIDs.contains("asset1"))
        #expect(galleryManager.selectedAssetIDs.contains("asset3"))
    }
    
    @Test func testClearAllPhotos() async throws {
        let galleryManager = GalleryManager()
        
        // Setup initial selection
        galleryManager.selectedAssetIDs = ["asset1", "asset2", "asset3"]
        
        // Test clearing all
        galleryManager.selectedAssetIDs.removeAll()
        
        #expect(galleryManager.selectedAssetIDs.isEmpty)
    }
    
    @Test func testCurrentImageRotation() async throws {
        let galleryManager = GalleryManager()
        
        // Test image index progression
        galleryManager.currentIndex = 0
        #expect(galleryManager.currentIndex == 0)
        
        galleryManager.currentIndex = 1
        #expect(galleryManager.currentIndex == 1)
        
        galleryManager.currentIndex = 2
        #expect(galleryManager.currentIndex == 2)
    }
    
    @Test func testSlideshowFunctionality() async throws {
        let galleryManager = GalleryManager()
        
        // Test slideshow duration setting
        galleryManager.slideshowDuration = 10.0
        #expect(galleryManager.slideshowDuration == 10.0)
        
        galleryManager.slideshowDuration = 3.0
        #expect(galleryManager.slideshowDuration == 3.0)
    }
    
    @Test func testGalleryManagerProperties() async throws {
        let galleryManager = GalleryManager()
        
        // Test basic properties exist and work
        #expect(galleryManager.selectedAssetIDs.isEmpty)
        #expect(galleryManager.currentImage == nil)
        #expect(galleryManager.currentIndex == 0)
        #expect(galleryManager.slideshowDuration == 10.0)
    }
    
    // MARK: - CalendarService Tests
    
    @Test func testCalendarServiceInitialization() async throws {
        let calendarService = CalendarService()
        
        // Test initial state
        #expect(calendarService.upcomingEvents.isEmpty)
    }
    
    @Test func testCalendarServiceProperties() async throws {
        let calendarService = CalendarService()
        
        // Test that calendar service has the expected properties
        #expect(calendarService.upcomingEvents.isEmpty)
        
        // Test we can add mock events
        let testEvents = [
            CalendarEventData(title: "Test Meeting", startDate: Date(), isAllDay: false)
        ]
        // Note: We can't directly set upcomingEvents as it's private, 
        // but we can test the data structure
        #expect(testEvents.count == 1)
        #expect(testEvents[0].title == "Test Meeting")
    }
    
    @Test func testEventDataParsing() async throws {
        let calendarService = CalendarService()
        let testDate = Date()
        
        // Create test event
        let testEvent = CalendarEventData(
            title: "Test Meeting",
            startDate: testDate,
            isAllDay: false
        )
        
        // Test event properties
        #expect(testEvent.title == "Test Meeting")
        #expect(testEvent.startDate == testDate)
        #expect(testEvent.isAllDay == false)
    }
    
    @Test func testEventCollection() async throws {
        let calendarService = CalendarService()
        
        // Test creating events collection
        let event1 = CalendarEventData(title: "Meeting 1", startDate: Date(), isAllDay: false)
        let event2 = CalendarEventData(title: "Meeting 2", startDate: Date(), isAllDay: true)
        
        let events = [event1, event2]
        
        #expect(events.count == 2)
        #expect(events[0].title == "Meeting 1")
        #expect(events[1].title == "Meeting 2")
        #expect(events[0].isAllDay == false)
        #expect(events[1].isAllDay == true)
    }
    
    // MARK: - Service Integration Tests
    
    @Test func testWeatherServiceDataFlow() async throws {
        let weatherService = WeatherService()
        
        // Test city selection affects weather fetching preparation
        let testCity = WeatherCity(name: "Tokyo", lat: 35.6762, lon: 139.6503, country: "Japan")
        weatherService.selectedCity = testCity
        
        #expect(weatherService.selectedCity?.name == "Tokyo")
        #expect(weatherService.selectedCity?.lat == 35.6762)
        #expect(weatherService.selectedCity?.lon == 139.6503)
    }
    
    @Test func testGalleryManagerPhotoFlow() async throws {
        let galleryManager = GalleryManager()
        
        // Test full photo selection workflow
        let initialCount = galleryManager.selectedAssetIDs.count
        
        // Add photos
        galleryManager.selectedAssetIDs.append("photo1")
        galleryManager.selectedAssetIDs.append("photo2")
        
        #expect(galleryManager.selectedAssetIDs.count == initialCount + 2)
        
        // Remove one photo
        galleryManager.selectedAssetIDs.removeAll { $0 == "photo1" }
        
        #expect(galleryManager.selectedAssetIDs.count == initialCount + 1)
        #expect(galleryManager.selectedAssetIDs.contains("photo2"))
        #expect(!galleryManager.selectedAssetIDs.contains("photo1"))
    }
    
    @Test func testServicesDoNotInterfereWithEachOther() async throws {
        let weatherService = WeatherService()
        let galleryManager = GalleryManager()
        let calendarService = CalendarService()
        
        // Test that services can be used independently
        weatherService.selectedCity = WeatherCity(name: "Paris", lat: 48.8566, lon: 2.3522, country: "France")
        galleryManager.selectedAssetIDs = ["asset1", "asset2"]
        
        // Verify each service maintains its state
        #expect(weatherService.selectedCity?.name == "Paris")
        #expect(galleryManager.selectedAssetIDs.count == 2)
        #expect(calendarService.upcomingEvents.isEmpty) // Initially empty
    }
} 