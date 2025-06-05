//
//  ForecastChart.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import Charts
import SwiftUI

struct ForecastChart: View {
    let weather: [TemperatureRecord]
    @State var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Environment(TempPrefManager.self) var tempPrefManager

    var body: some View {
        Chart {
            LinePlot(weather, x: .value("Time", \.date), y: .value("Temperature", \.temp))
            RuleMark(xStart: 0, xEnd: 500, y: .value("Target", tempPrefManager.preference?.temperature.converted(to: .fahrenheit).value ?? 76))
                .foregroundStyle(.blue)
            RuleMark(x: PlottableValue.value("Now", now))
                .foregroundStyle(.gray)
                .annotation {
                    Text(now, style: .time)
                }
        }
        .chartYScale(domain: temperatureRange)
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    var temperatureRange: ClosedRange<Double> {
        let temps = weather.map(\.temp)
        guard let min = temps.min(),
              let max = temps.max()
        else { return 0.0...0.0 }
        return (min - 5)...(max + 5)
    }
}

#Preview {
    ForecastChart(weather: TemperatureRecord.sampleData)
        .frame(maxHeight: 200)
        .padding()
}
