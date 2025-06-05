//
//  WindowsApp.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import SwiftUI

@main
struct WindowsApp: App {
    @State var locationManager: LocationManager = .init()
    @State var weatherManager: WeatherManager = .init()
    @State var homeManager: HomeManager = .init()
    @State var tempPrefManager: TempPrefManager = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .environment(weatherManager)
                .environment(homeManager)
                .environment(tempPrefManager)
        }
    }
}
