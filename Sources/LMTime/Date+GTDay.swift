//
//  Date+Day.swift
//
//  Created by Leko Murphy on 2/22/20.
//  Copyright © 2020 Leko Murphy. All rights reserved.
//

import Foundation

extension Date {
    func day(in timezone: TimeZone) -> Day {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let (month, day, year) = (calendar.component(.month, from: self), calendar.component(.day, from: self), calendar.component(.year, from: self))
        return Day(month: month, day: day, year: year)!
    }
}
