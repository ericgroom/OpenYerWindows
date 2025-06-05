//
//  TempPrefManager.swift
//  Windows
//
//  Created by Eric Groom on 6/5/25.
//

import Foundation

enum OverUnder: String, Equatable, Codable, CaseIterable {
    case over
    case under
}

struct TempPref: Equatable, Codable {
    var overUnder: OverUnder
    var temperature: Measurement<UnitTemperature>
}

@Observable
@MainActor
class TempPrefManager {
    let key = "user_temp_pref"
    var preference: TempPref? {
        didSet {
            guard let preference else { return } // TODO: clear
            let data = try! JSONEncoder().encode(preference)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            let result = try! JSONDecoder().decode(TempPref.self, from: data)
            self.preference = result
        }
    }
}
