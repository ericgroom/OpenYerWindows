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
    @Environment(LocationManager.self) var locationManager
    @Environment(WeatherManager.self) var weatherManager
    @Environment(HomeManager.self) var homeManager
    @Environment(TempPrefManager.self) var tempPrefManager
    @State var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    conditions
                }
                Section {
                    ForecastChart(weather: hourlyForecastForToday, inflectionPoints: inflectionPoints)
                        .frame(height: 200)
                        .padding(.vertical, 32)
                }
//                Section {
//                    ForEach(minutelyForecastForToday, id: \.date) { forecast in
//                        Text("\(forecast.date.formatted(hourlyFormat)) - \(projectedInteriorTemperature(outdoorTemperature: forecast.temperature)?.formatted())")
//                    }
//                }
            }
            .onChange(of: inflectionPoints) { oldValue, newValue in
                Task {
                    try! await scheduleNotifications(inflectionPoints: newValue)
                }
            }
            .onReceive(timer) { _ in
                now = Date()
            }
            .refreshable {
                guard let location = locationManager.location?.location else {
                    return
                }
                try? await weatherManager.updateWeather(location)
            }
            .sheet(isPresented: $showSettings, content: {
                SettingsView()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var conditions: some View {
        VStack {
            HStack(spacing: 32.0) {
                Spacer()
                VStack {
                    Image(systemName: "sun.max.fill")
                    Text("\(exteriorTemperature?.formatted(shortTemp) ?? "unknown")")
                }
                Divider()
                VStack(alignment: .center) {
                    Image(systemName: "house.fill")
                    Text("\(interiorTemperature?.formatted(shortTemp) ?? "unknown")")
                }
                Spacer()
            }
            .font(.system(size: 32))
            .monospacedDigit()
            .padding(.vertical, 16)
            switch recommendation {
            case .closeWindows:
                Text("Keep your windows closed for now")
                    .font(.headline)
            case .openWindows:
                Text("You can open your windows to let in some cooler air")
                    .font(.headline)
            case .undetermined:
                EmptyView()
            }
            if let nextInflectionPoint {
                let verb = switch nextInflectionPoint.recommendation {
                case .closeWindows:
                    "close"
                case .openWindows:
                    "open"
                case .undetermined:
                    "idk"
                }
                Text("You should \(verb) your windows at \(nextInflectionPoint.record.date.formatted(hourlyFormat))")
                    .font(.caption)
            }
            if let wind = weatherManager.weather?.currentWeather.wind {
                Text("Wind \(wind.speed.formatted()) from \(wind.compassDirection.abbreviation)")
                    .font(.caption2)
            }
        }
    }

    var nextInflectionPoint: RecommendationWithContext? {
        inflectionPoints
            .first { $0.record.date > now }
    }

    @ViewBuilder
    private func inflectionPointView(_ point: RecommendationWithContext) -> some View {
        Text("\(point.record.date.formatted(hourlyFormat))  \(point.record.temperature.formatted(shortTemp)):  \(point.recommendation.displayText)")
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

    private func projectedInteriorTemperature(outdoorTemperature: Measurement<UnitTemperature>) -> Measurement<UnitTemperature>? {
        let targetIndoorTemp = tempPrefManager.preference?.temperature
        return targetIndoorTemp ?? outdoorTemperature
    }

    var inflectionPoints: [RecommendationWithContext] {
        let forecast = minutelyForecastForToday
        var result: [RecommendationWithContext] = []

        result = forecast.reduce(into: [RecommendationWithContext]()) { partialResult, forecast in
            let interiorTemperature = projectedInteriorTemperature(outdoorTemperature: forecast.temperature)
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
