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
