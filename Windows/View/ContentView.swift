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
                ForecastChart(weather: hourlyForecast.map { $0.0 }.map { TemperatureRecord(weather: $0)})
            }
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
        }
    }

    var hourlyFormat: Date.FormatStyle {
        Date.FormatStyle()
            .hour(.conversationalDefaultDigits(amPM: .abbreviated))
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

    var hourlyForecast: [(HourWeather, Recommendation)] {
        guard let weather = weatherManager.weather else { return [] }
        let forecast = weather.hourlyForecast
        guard let interiorTemperature else { return [] }
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        debugPrint(forecast
            .filter { hour in
                hour.date >= startOfToday && hour.date < endOfToday
            }
            .map { hour in
                (hour.date.timeIntervalSince1970, hour.temperature)
        })
        return forecast
            .filter { hour in
                hour.date >= startOfToday && hour.date < endOfToday
            }
            .map { hour in
            (hour, Recommendation(interiorTemperature: interiorTemperature, exteriorTemperature: hour.temperature))
        }
    }
}

#Preview {
    ContentView()
}
