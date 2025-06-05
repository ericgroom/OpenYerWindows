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
    @Environment(LocationManager.self) var locationManager
    @Environment(WeatherManager.self) var weatherManager
    @Environment(HomeManager.self) var homeManager
    @State var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                ForEach(inflectionPoints, id: \.record.date) { point in
                    Text("\(point.record.date.formatted(hourlyFormat))  \(point.record.temperature.formatted(shortTemp)):  \(point.recommendation.displayText)")
                }
            }
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
        }
        .onChange(of: inflectionPoints) { oldValue, newValue in
            Task {
                try! await scheduleNotifications(inflectionPoints: newValue)
            }
        }
        .onReceive(timer) { _ in
            now = Date()
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
        let now = self.now
        let closestToNow = minutelyForecastForToday.min { lhs, rhs in
            abs(lhs.date.distance(to: now)) < abs(rhs.date.distance(to: now))
        }
        return closestToNow?.temperature
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
        let now = self.now
        let dateRange = Calendar.autoupdatingCurrent.daySpanning(date: now)
        return forecast
            .between(start: dateRange.lowerBound, end: dateRange.upperBound)
            .map { TemperatureRecord(weather: $0) }
    }

    var minutelyForecastForToday: [TemperatureRecord] {
        zip(hourlyForecastForToday, hourlyForecastForToday.dropFirst())
            .flatMap { start, end in
                TemperatureRecord.lerp(start: start, end: end, steps: 60)
                    .dropLast()
            }
    }

    var inflectionPoints: [RecommendationWithContext] {
        guard let interiorTemperature else { return [] }
        let forecast = minutelyForecastForToday
        var result: [RecommendationWithContext] = []

        result = forecast.reduce(into: [RecommendationWithContext]()) { partialResult, forecast in
            let recommendation = Recommendation(interiorTemperature: interiorTemperature, exteriorTemperature: forecast.temperature)
            if recommendation != partialResult.last?.recommendation {
                partialResult.append(RecommendationWithContext(recommendation: recommendation, record: forecast))
            }
        }

        result.removeFirst()
        return result
    }

    private func scheduleNotifications(inflectionPoints: [RecommendationWithContext]) async throws {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for point in inflectionPoints {
            let record = point.record
            let recommendation = point.recommendation
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
