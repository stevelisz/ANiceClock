import Foundation
import CoreLocation

// Enhanced Weather Service using Open-Meteo API (Free, no API key required)
class WeatherService: NSObject, ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: [ForecastItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCity: WeatherCity?
    @Published var currentLocationName: String?
    @Published var availableCities: [WeatherCity] = [
        WeatherCity(name: "New York", lat: 40.7128, lon: -74.0060, country: "US"),
        WeatherCity(name: "London", lat: 51.5074, lon: -0.1278, country: "GB"),
        WeatherCity(name: "Tokyo", lat: 35.6762, lon: 139.6503, country: "JP"),
        WeatherCity(name: "Paris", lat: 48.8566, lon: 2.3522, country: "FR"),
        WeatherCity(name: "Sydney", lat: -33.8688, lon: 151.2093, country: "AU"),
        WeatherCity(name: "Los Angeles", lat: 34.0522, lon: -118.2437, country: "US"),
        WeatherCity(name: "Berlin", lat: 52.5200, lon: 13.4050, country: "DE"),
        WeatherCity(name: "Singapore", lat: 1.3521, lon: 103.8198, country: "SG"),
        WeatherCity(name: "Toronto", lat: 43.6532, lon: -79.3832, country: "CA"),
        WeatherCity(name: "Dubai", lat: 25.2048, lon: 55.2708, country: "AE")
    ]
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather() {
        print("🔄 fetchWeather called - selectedCity: \(selectedCity?.name ?? "nil")")
        print("🔐 Location authorization: \(locationManager.authorizationStatus.rawValue)")
        
        if let city = selectedCity {
            // Use selected city
            print("🏙️ Using selected city: \(city.name)")
            fetchWeatherForLocation(lat: city.lat, lon: city.lon, cityName: city.name)
        } else {
            // Use current location only if authorized
            guard locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways else {
                // No fallback - clear weather data if no permission
                print("❌ Location permission not granted")
                DispatchQueue.main.async {
                    self.currentWeather = nil
                    self.forecast = []
                    self.errorMessage = "Location permission required for weather"
                }
                return
            }
            print("📍 Requesting current location")
            locationManager.requestLocation()
        }
    }
    
    func selectCity(_ city: WeatherCity?) {
        selectedCity = city
        fetchWeather()
    }
    
    private func fetchWeatherForLocation(lat: Double, lon: Double, cityName: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        print("🌤️ Fetching weather for: \(cityName ?? "Unknown") at \(lat), \(lon)")
        
        // Open-Meteo API - Free, no API key required!
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=7"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.currentWeather = nil
                    self.forecast = []
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    self.currentWeather = nil
                    self.forecast = []
                    return
                }
                
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                    self.currentWeather = weatherData
                    self.generateForecastFromDaily(weatherData, cityName: cityName)
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Failed to decode weather data: \(error.localizedDescription)"
                    self.currentWeather = nil
                    self.forecast = []
                }
            }
        }.resume()
    }
    
    private func generateForecastFromDaily(_ weatherData: WeatherData, cityName: String?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        forecast = zip(weatherData.daily.time, zip(weatherData.daily.temperature_2m_max, weatherData.daily.weather_code)).enumerated().map { index, element in
            let (dateString, (maxTemp, weatherCode)) = element
            
            if let date = dateFormatter.date(from: dateString) {
                return ForecastItem(
                    dt: Int(date.timeIntervalSince1970),
                    main: MainWeather(temp: maxTemp, feels_like: maxTemp, humidity: 50),
                    weather: [WeatherCondition(main: weatherCodeToCondition(weatherCode),
                                             description: weatherCodeToDescription(weatherCode),
                                             icon: "")],
                    dt_txt: dateString
                )
            } else {
                return ForecastItem(
                    dt: Int(Date().timeIntervalSince1970) + (index * 86400),
                    main: MainWeather(temp: maxTemp, feels_like: maxTemp, humidity: 50),
                    weather: [WeatherCondition(main: weatherCodeToCondition(weatherCode),
                                             description: weatherCodeToDescription(weatherCode),
                                             icon: "")],
                    dt_txt: dateString
                )
            }
        }
    }
}

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        print("📍 Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Get location name using reverse geocoding
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    self?.currentLocationName = "Current Location"
                    self?.fetchWeatherForLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude, cityName: "Current Location")
                } else if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown Location"
                    print("🏙️ Reverse geocoded location: \(city)")
                    print("🗺️ Full placemark: \(placemark)")
                    self?.currentLocationName = city
                    self?.fetchWeatherForLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude, cityName: city)
                } else {
                    print("⚠️ No placemark found")
                    self?.currentLocationName = "Current Location"
                    self?.fetchWeatherForLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude, cityName: "Current Location")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location access failed"
            self.currentWeather = nil
            self.forecast = []
            self.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Only fetch weather if no city is selected (using current location)
            if selectedCity == nil {
                fetchWeather()
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied"
                self.currentWeather = nil
                self.forecast = []
                self.currentLocationName = nil
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
} 