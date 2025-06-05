//
//  TemperatureRecord.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import Foundation
import WeatherKit

struct TemperatureRecord: Equatable {
    let date: Date
    let temperature: Measurement<UnitTemperature>

    var temp: Double { temperature.converted(to: .fahrenheit).value }
}

extension TemperatureRecord {
    init(weather: HourWeather) {
        self.date = weather.date
        self.temperature = weather.temperature
    }
}

extension TemperatureRecord {
    static func lerp(start: TemperatureRecord, end: TemperatureRecord, steps: Int) -> [TemperatureRecord] {
        precondition(start.date < end.date)
        let endTime = end.date.timeIntervalSince1970
        let startTime = start.date.timeIntervalSince1970
        let timeStep = (endTime - startTime) / Double(steps)

        let endTemp = end.temperature
        let startTemp = start.temperature
        let tempStep = (endTemp - startTemp) / Double(steps)

        var previous = start
        var result = [start]
        var remainingSteps = steps - 1

        while remainingSteps > 0 {
            defer { remainingSteps -= 1 }
            let record = TemperatureRecord(date: previous.date.addingTimeInterval(timeStep), temperature: previous.temperature + tempStep)
            defer { previous = record }
            result.append(record)
        }

        result.append(end)
        return result
    }
}

extension TemperatureRecord {
    static var sampleData: [TemperatureRecord] {
        [
            .init(date: Date(timeIntervalSince1970: 1749020400.0), temperature: Measurement<UnitTemperature>(value: 19.959999084472656, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749024000.0), temperature: Measurement<UnitTemperature>(value: 18.799999237060547, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749027600.0), temperature: Measurement<UnitTemperature>(value: 17.639999389648438, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749031200.0), temperature: Measurement<UnitTemperature>(value: 17.170000076293945, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749034800.0), temperature: Measurement<UnitTemperature>(value: 16.579999923706055, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749038400.0), temperature: Measurement<UnitTemperature>(value: 15.960000038146973, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749042000.0), temperature: Measurement<UnitTemperature>(value: 15.180000305175781, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749045600.0), temperature: Measurement<UnitTemperature>(value: 16.6200008392334  , unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749049200.0), temperature: Measurement<UnitTemperature>(value: 19.190000534057617, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749052800.0), temperature: Measurement<UnitTemperature>(value: 21.969999313354492, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749056400.0), temperature: Measurement<UnitTemperature>(value: 24.600000381469727, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749060000.0), temperature: Measurement<UnitTemperature>(value: 26.389999389648438, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749063600.0), temperature: Measurement<UnitTemperature>(value: 27.6299991607666  , unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749067200.0), temperature: Measurement<UnitTemperature>(value: 30.010000228881836, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749070800.0), temperature: Measurement<UnitTemperature>(value: 31.600000381469727, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749074400.0), temperature: Measurement<UnitTemperature>(value: 32.93000030517578 , unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749078000.0), temperature: Measurement<UnitTemperature>(value: 33.790000915527344, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749081600.0), temperature: Measurement<UnitTemperature>(value: 33.81999969482422 , unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749085200.0), temperature: Measurement<UnitTemperature>(value: 32.2400016784668  , unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749088800.0), temperature: Measurement<UnitTemperature>(value: 29.969999313354492, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749092400.0), temperature: Measurement<UnitTemperature>(value: 26.959999084472656, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749096000.0), temperature: Measurement<UnitTemperature>(value: 23.770000457763672, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749099600.0), temperature: Measurement<UnitTemperature>(value: 21.530000686645508, unit: .celsius)),
            .init(date: Date(timeIntervalSince1970: 1749103200.0), temperature: Measurement<UnitTemperature>(value: 20.059999465942383, unit: .celsius))
        ]
    }
}
