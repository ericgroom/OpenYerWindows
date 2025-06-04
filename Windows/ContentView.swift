//
//  ContentView.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import SwiftUI
import WeatherKit
import CoreLocation

struct ContentView: View {
    @State var manager = Manager()
    @State var address = ""
    @State var isFetching = false
    @State var location: CLPlacemark? = nil
    @State var weather: Weather? = nil

    var body: some View {
        Form {
            TextField("Address", text: $address)
            Button("Fetch Location") {
                guard !isFetching else { return }
                isFetching = true
                Task {
                    defer { isFetching = false }
                    self.location = try! await manager.getLocation(address: address)
                }
            }
            Button("Fetch Weather") {
                guard !isFetching else { return }
                isFetching = true
                Task {
                    defer { isFetching = false }
                    self.weather = try! await manager.getWeather(location: location!.location!)
                }
            }.disabled(location == nil)
            if isFetching {
                ProgressView()
            }
            Text("Weather: \(weather?.currentWeather.temperature.converted(to: .fahrenheit))")
                .lineLimit(nil)
        }
    }
}

#Preview {
    ContentView()
}
