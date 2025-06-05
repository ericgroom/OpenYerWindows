//
//  SettingsView.swift
//  Windows
//
//  Created by Eric Groom on 6/5/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(LocationManager.self) var locationManager

    var body: some View {
        NavigationStack {
            Form {
                NavigationLink(setLocationText) {
                    HomeLocationForm()
                }
                Section {
                    TempPrefForm()
                }
            }
        }
    }

    private var setLocationText: String {
        if locationManager.location == nil {
            "Set Home Location"
        } else {
            "Change Home Location"
        }
    }
}

struct TempPrefForm: View {
    @Environment(TempPrefManager.self) var tempPrefManager

    var body: some View {
        @Bindable var tempPref = tempPrefManager
        VStack {
            Text("Set your target temperature")
            Divider()
            Picker("OverUnder", selection: overUnderBinding) {
                Text("Keep Over").tag(OverUnder.over)
                Text("Keep Under").tag(OverUnder.under)
            }
            Divider()
            TextField("Temperature", value: tempBinding, format: .number)
            Divider()
        }
    }

    var tempBinding: Binding<Double> {
        Binding {
            tempPrefManager.preference?.temperature.converted(to: .fahrenheit).value ?? 0.0
        } set: { newValue in
            let asMeasurement = Measurement<UnitTemperature>(value: newValue, unit: .fahrenheit)
            let preference = TempPref(overUnder: overUnderBinding.wrappedValue, temperature: asMeasurement)
            tempPrefManager.preference = preference
        }
    }

    var overUnderBinding: Binding<OverUnder> {
        Binding {
            tempPrefManager.preference?.overUnder ?? .under
        } set: { newValue in
            let preference = TempPref(overUnder: newValue, temperature: tempPrefManager.preference?.temperature ?? Measurement(value: 0.0, unit: .fahrenheit))
            tempPrefManager.preference = preference
        }
    }
}

struct HomeLocationForm: View {
    @State var address = ""
    @State var isFetching = false
    @Environment(LocationManager.self) var locationManager

    var body: some View {
        Form {
            TextField("Address", text: $address)
            Button("Set Location") {
                guard !isFetching else { return }
                isFetching = true
                Task {
                    defer { isFetching = false }
                    try! await locationManager.setAddress(address)
                }
            }
            if isFetching {
                ProgressView()
            }
        }
        .onAppear {
            address = locationManager.location?.name ?? ""
        }
    }
}
