//
//  Manager.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import CoreLocation
import WeatherKit

class Manager {
    enum Error: Swift.Error {
        case unableToGetLocation
    }
    func getLocation(address: String) async throws -> CLPlacemark {
        print("Getting location for \(address)")
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let likelyLocation = placemarks.first else { throw Error.unableToGetLocation }
        return likelyLocation
    }

    func getWeather(location: CLLocation) async throws -> Weather {
        print("Getting weather for \(location)")
        let weather = try await WeatherService.shared.weather(for: location)
        return weather
    }
}
