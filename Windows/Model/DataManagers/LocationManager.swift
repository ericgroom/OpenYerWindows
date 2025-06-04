//
//  LocationManager.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import CoreLocation
import Foundation

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

    enum Error: Swift.Error {
        case unableToGetLocation
    }

    func setAddress(_ address: String) async throws {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let likelyLocation = placemarks.first else { throw Error.unableToGetLocation }
        self.location = likelyLocation
    }
}
