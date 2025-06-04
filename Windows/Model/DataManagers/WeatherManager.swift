//
//  WeatherManager.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import CoreLocation
import Foundation
@preconcurrency import WeatherKit

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
        weather = try await WeatherService.shared.weather(for: location)
    }
}
