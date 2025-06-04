//
//  ContentView.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import SwiftUI
@preconcurrency import WeatherKit
import CoreLocation
import HomeKit

@Observable
@MainActor
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
@MainActor
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

@Observable
@MainActor
class HomeManager: NSObject, HMHomeManagerDelegate {
    var homes: [HMHome] = []
    private let manager: HMHomeManager

    override init() {
        manager = HMHomeManager()
        super.init()
        manager.delegate = self
    }

    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in
            self.homes = manager.homes
        }
    }

    func temperature() -> Measurement<UnitTemperature>? {
        guard let primaryHome = homes.first else { return nil }
        let services = primaryHome.servicesWithTypes([HMServiceTypeThermostat])!
        for service in services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature {
                    if characteristic.service?.accessory?.name == "Truck Climate" {
                        continue
                    }
                    if let value = characteristic.value as? Double {
                        let temp = Measurement(value: value, unit: UnitTemperature.celsius)
                        return temp
                    }
                }
            }
        }
        return nil
    }
}

enum Recommendation {
    case closeWindows
    case openWindows
    case undetermined

    var displayText: String {
        switch self {
        case .closeWindows:
            return "Close yer windows"
        case .openWindows:
            return "Open yer windows"
        case .undetermined:
            return "I dunno"
        }
    }

    init(interiorTemperature: Measurement<UnitTemperature>?, exteriorTemperature: Measurement<UnitTemperature>?) {
        guard let exteriorTemperature, let interiorTemperature else {
            self = .undetermined
            return
        }
        if exteriorTemperature >= interiorTemperature {
           self = .closeWindows
        } else {
            self = .openWindows
        }
    }
}

struct ContentView: View {
    @State var manager = Manager()
    @State var address = ""
    @State var isFetching = false
    @State var locationManager = LocationManager()
    @State var weatherManager = WeatherManager()
    @State var homeManager = HomeManager()

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
            Text("Exterior temp: \(exteriorTemperature?.formatted() ?? "unknown")")
            Text("Interior temp: \(homeManager.temperature()?.formatted() ?? "unknown")")
            Text(recommendation.displayText)
            Section {
                ForEach(asdf, id: \.0.date) { forecast, recommendation in
                    Text("\(forecast.date.formatted(hourlyFormat))  \(forecast.temperature.formatted(shortTemp)):  \(recommendation.displayText)")
                }
            }
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
        }
    }

    var hourlyFormat: Date.FormatStyle {
        Date.FormatStyle()
            .hour(.conversationalDefaultDigits(amPM: .abbreviated))
    }

    var shortTemp: Measurement<UnitTemperature>.FormatStyle {
        Measurement<UnitTemperature>.FormatStyle(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
    }

    var exteriorTemperature: Measurement<UnitTemperature>? {
        weatherManager.weather?.currentWeather.temperature
    }

    var interiorTemperature: Measurement<UnitTemperature>? {
        homeManager.temperature()
    }

    var recommendation: Recommendation {
        Recommendation(interiorTemperature: interiorTemperature, exteriorTemperature: exteriorTemperature)
    }

    var asdf: [(HourWeather, Recommendation)] {
        guard let weather = weatherManager.weather else { return [] }
        let forecast = weather.hourlyForecast
        guard let interiorTemperature else { return [] }
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        return forecast
            .filter { hour in
                hour.date >= startOfToday && hour.date < endOfToday
            }
            .map { hour in
            (hour, Recommendation(interiorTemperature: interiorTemperature, exteriorTemperature: hour.temperature))
        }
    }
}

#Preview {
    ContentView()
}
