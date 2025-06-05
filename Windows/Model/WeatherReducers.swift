//
//  WeatherReducers.swift
//  Windows
//
//  Created by Eric Groom on 6/5/25.
//

import Foundation
import WeatherKit

extension Forecast<HourWeather> {
    func between(start: Date, end: Date) -> [HourWeather] {
        self.filter { hour in
            hour.date >= start && hour.date <= end
        }
    }
}
