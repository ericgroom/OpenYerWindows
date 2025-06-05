//
//  CalendarHelpers.swift
//  Windows
//
//  Created by Eric Groom on 6/5/25.
//

import Foundation

extension Calendar {
    func daySpanning(date: Date) -> ClosedRange<Date> {
        let startOfDay = self.startOfDay(for: date)
        let endOfDay = self.date(byAdding: .day, value: 1, to: startOfDay)!
        return startOfDay...endOfDay
    }
}
