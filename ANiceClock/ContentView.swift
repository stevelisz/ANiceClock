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
    @AppStorage("ANiceClock_brightness") private var brightness: Double = 0.8
    @AppStorage("ANiceClock_isNightMode") private var isNightMode = false
    @AppStorage("ANiceClock_isAutoNightMode") private var isAutoNightMode = true
    @State private var showSettings = false
    @AppStorage("ANiceClock_is24HourFormat") private var is24HourFormat = false
    @AppStorage("ANiceClock_showSeconds") private var showSeconds = true
    @AppStorage("ANiceClock_showDate") private var showDate = true
    @AppStorage("ANiceClock_showWeather") private var showWeather = true
    @AppStorage("ANiceClock_showBattery") private var showBattery = true
    @AppStorage("ANiceClock_showCalendar") private var showCalendar = true
    @AppStorage("ANiceClock_nightColorTheme") private var nightColorTheme: NightColorTheme = .red
    @AppStorage("ANiceClock_fontFamily") private var fontFamily: FontFamily = .system

    @State private var batteryLevel: Float = 0.0
    @State private var isCharging = false
    @State private var deviceOrientation = UIDeviceOrientation.unknown
    @AppStorage("ANiceClock_viewMode") private var viewMode: ViewMode = .clock
    @AppStorage("ANiceClock_glassPanelOpacity") private var glassPanelOpacity: Double = 0.85
    
    @StateObject private var weatherService = WeatherService()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var galleryManager = GalleryManager()
    @State private var showingPhotoPicker = false
    @AppStorage("ANiceClock_galleryDuration") private var galleryDuration: Double = 10.0
    
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
                        fontFamily: $fontFamily,
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
                        fontFamily: fontFamily,
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
            // Sync gallery duration with manager
            galleryManager.updateSlideshowDuration(galleryDuration)
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
                fontFamily: $fontFamily,
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
