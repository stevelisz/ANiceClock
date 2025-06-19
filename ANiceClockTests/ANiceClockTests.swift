//
//  ANiceClockTests.swift
//  ANiceClockTests
//
//  Created by Steve Li on 6/17/25.
//

import Testing
@testable import ANiceClock

struct ANiceClockTests {

    @Test func testAppLaunchState() async throws {
        // Test that the app can initialize properly
        let weatherService = WeatherService()
        let galleryManager = GalleryManager()
        
        // Verify services initialize correctly
        #expect(weatherService.currentWeather == nil)
        #expect(galleryManager.selectedAssetIDs.isEmpty)
    }

}
