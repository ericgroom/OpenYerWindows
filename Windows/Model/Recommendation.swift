//
//  Recommendation.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import Foundation

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
