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
import UserNotifications

struct ContentView: View {
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
                ForecastChart(weather: hourlyForecastForToday)
            }
            Section {
                ForEach(inflectionPoints, id: \.0.date) { record, recommendation in
                    Text("\(record.date.formatted(hourlyFormat))  \(record.temperature.formatted(shortTemp)):  \(recommendation.displayText)")
                }
            }
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
            Task {
                try! await scheduleNotifications()
            }
        }
    }

    var hourlyFormat: Date.FormatStyle {
        Date.FormatStyle()
            .hour(.conversationalDefaultDigits(amPM: .abbreviated))
            .minute()
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

    var hourlyForecastForToday: [TemperatureRecord] {
        guard let weather = weatherManager.weather else { return [] }
        let forecast = weather.hourlyForecast
        let now = Date()
        let dateRange = Calendar.autoupdatingCurrent.daySpanning(date: now)
        return forecast
            .between(start: dateRange.lowerBound, end: dateRange.upperBound)
            .map { TemperatureRecord(weather: $0) }
    }

    var inflectionPoints: [(TemperatureRecord, Recommendation)] {
        guard let interiorTemperature else { return [] }
        let forecast = hourlyForecastForToday
        var result: [(TemperatureRecord, Recommendation)] = []
        guard var previous = forecast.first else { return [] }
        for hour in forecast[1...] {
            defer { previous = hour }
            let lerped = TemperatureRecord.lerp(start: previous, end: hour, steps: 60)
            let withRecs = lerped.map { ($0, Recommendation(interiorTemperature: interiorTemperature, exteriorTemperature: $0.temperature))}
            result.append(contentsOf: withRecs)
        }

        result = result.reduce(into: [(TemperatureRecord, Recommendation)]()) { partialResult, next in
            let (record, rec) = next
            if rec != partialResult.last?.1 {
                partialResult.append(next)
            }
        }

        result.removeFirst()
        return result
    }

    private func scheduleNotifications() async throws {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for (record, recommendation) in inflectionPoints {
            guard record.date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = recommendation.displayText
            content.body = "It is \(record.temperature.formatted()) outside."
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let components = Calendar.autoupdatingCurrent.dateComponents(in: .autoupdatingCurrent, from: record.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            try await UNUserNotificationCenter.current().add(request)
            print("scheduled notification for \(record.date)")
        }
    }
}

#Preview {
    ContentView()
}
