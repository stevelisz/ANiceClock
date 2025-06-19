//
//  ContentView.swift
//  ANiceClock
//
//  Created by Steve Li on 6/17/25.
//

import SwiftUI
import CoreLocation
import EventKit
import Photos

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
    @State private var viewMode: ViewMode = .clock
    @State private var glassPanelOpacity: Double = 0.85 // Default glass panel opacity
    
    @StateObject private var weatherService = WeatherService()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var galleryManager = GalleryManager()
    @State private var showingPhotoPicker = false
    @State private var galleryDuration: Double = 10.0 // Slideshow duration in seconds
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // View Mode Content
                switch viewMode {
                case .clock:
                    ElegantClockView(
                        currentTime: $currentTime,
                        brightness: $brightness,
                        isNightMode: $isNightMode,
                        isAutoNightMode: $isAutoNightMode,
                        showSettings: $showSettings,
                        is24HourFormat: $is24HourFormat,
                        showSeconds: $showSeconds,
                        showDate: $showDate,
                        showWeather: $showWeather,
                        showBattery: $showBattery,
                        showCalendar: $showCalendar,
                        nightColorTheme: $nightColorTheme,
                        batteryLevel: $batteryLevel,
                        isCharging: $isCharging,
                        deviceOrientation: $deviceOrientation,
                        viewMode: $viewMode,
                        weatherService: weatherService,
                        calendarService: calendarService
                    )
                    
                case .gallery:
                    GalleryView(
                        currentTime: currentTime,
                        brightness: brightness,
                        is24HourFormat: is24HourFormat,
                        showSeconds: showSeconds,
                        showDate: showDate,
                        showWeather: showWeather,
                        glassPanelOpacity: glassPanelOpacity,
                        weatherService: weatherService,
                        galleryManager: galleryManager,
                        onTapToGoBack: {
                            viewMode = .clock
                        }
                    )
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
            // Initialize brightness to a reasonable default (80%)
            brightness = 0.8
            // Sync UI with the saved gallery duration from manager
            galleryDuration = galleryManager.slideshowDuration
            print("🔆 App brightness initialized to: \(brightness)")
            print("🔵 Synced gallery duration from manager: \(galleryDuration)")
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
                glassPanelOpacity: $glassPanelOpacity,
                weatherService: weatherService,
                viewMode: $viewMode,
                galleryManager: galleryManager,
                showingPhotoPicker: $showingPhotoPicker,
                galleryDuration: $galleryDuration
            )
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
}
