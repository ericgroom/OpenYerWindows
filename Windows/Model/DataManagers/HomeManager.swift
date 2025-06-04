//
//  HomeManager.swift
//  Windows
//
//  Created by Eric Groom on 6/4/25.
//

import Foundation
import HomeKit

@Observable
@MainActor
class HomeManager: NSObject, HMHomeManagerDelegate {
    var homes: [HMHome] = []
    private let manager: HMHomeManager

    override init() {
        manager = HMHomeManager()
        super.init()
        manager.delegate = self
    }

    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in
            self.homes = manager.homes
        }
    }

    func temperature() -> Measurement<UnitTemperature>? {
        guard let primaryHome = homes.first else { return nil }
        let services = primaryHome.servicesWithTypes([HMServiceTypeThermostat])!
        for service in services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature {
                    if characteristic.service?.accessory?.name == "Truck Climate" {
                        continue
                    }
                    if let value = characteristic.value as? Double {
                        let temp = Measurement(value: value, unit: UnitTemperature.celsius)
                        return temp
                    }
                }
            }
        }
        return nil
    }
}
