//
//  ContentView.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import SwiftUI
import WeatherKit
import CoreLocation

@Observable
class LocationManager {
    let key = "user_location"
    var location: CLPlacemark? {
        didSet {
            print("setting location to \(location)")
            guard let location else { return } // TODO: clear
            let data = try! NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            let result = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLPlacemark.self, from: data)
            self.location = result
        }
    }

    func setAddress(_ address: String) async throws {
        self.location = try await Manager().getLocation(address: address)
    }
}

@Observable
class WeatherManager {
    let key = "user_weather"
    var weather: Weather? {
        didSet {
            print("setting weather to \(weather)")
            guard let weather else { return } // TODO: clear
            let data = try! JSONEncoder().encode(weather)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            let result = try! JSONDecoder().decode(Weather.self, from: data)
            self.weather = result
        }
    }

    func updateWeather(_ location: CLLocation) async throws {
        self.weather = try await Manager().getWeather(location: location)
    }
}

struct ContentView: View {
    @State var manager = Manager()
    @State var address = ""
    @State var isFetching = false
    @State var locationManager = LocationManager()
    @State var weatherManager = WeatherManager()

    var body: some View {
        Form {
            TextField("Address", text: $address)
            Button("Fetch Location") {
                guard !isFetching else { return }
                isFetching = true
                Task {
                    defer { isFetching = false }
                    try! await locationManager.setAddress(address)
                }
            }
            Button("Fetch Weather") {
                guard !isFetching else { return }
                isFetching = true
                Task {
                    defer { isFetching = false }
                    try await weatherManager.updateWeather(locationManager.location!.location!)
                }
            }.disabled(locationManager.location == nil)
            if isFetching {
                ProgressView()
            }
            Text("Weather: \(weatherManager.weather?.currentWeather.temperature.converted(to: .fahrenheit))")
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
        }
    }
}

#Preview {
    ContentView()
}
