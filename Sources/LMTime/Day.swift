//
//  LMDay.swift
//
//  Created by Leko Murphy on 2/22/20.
//  Copyright © 2020 Leko Murphy. All rights reserved.
//

import Foundation

public struct Day: Codable, Comparable, Strideable, Hashable {
    /// days are counted in integer intervals
    public typealias Stride = Int
    
    /// Internal UTC calendar used in this class
    private static let calendar: Calendar = {
        var cal = Calendar.init(identifier: .gregorian)
        cal.locale = Locale.init(identifier: "en_US")
        guard let timezone = TimeZone.init(identifier: "UTC") else { fatalError("WTF Apple, UTC timezone no longer exists") }
        cal.timeZone = timezone
        return cal
    }()
    
    private let date: Date
    
    var month: Int {
        return Day.calendar.component(.month, from: date)
    }
    
    var day: Int {
        return Day.calendar.component(.day, from: date)
    }
    
    var year: Int {
        return Day.calendar.component(.year, from: date)
    }
        
    /// Returns GTDay in user's local timezone
    static var today: Day {
        let todayDate = Date(timeIntervalSinceNow: 0)
        return todayDate.day(in: Calendar.autoupdatingCurrent.timeZone)
    }
    
    /// Returns `TimeInterval` corresponding to seconds since UTC epoch of start of day
    var start: TimeInterval {
        return date.timeIntervalSince1970
    }
    
    func start(inTimeZone timeZone: TimeZone) -> Date {
        let components = DateComponents(year: self.year, month: self.month, day: self.day)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: components)! // these components come from a valid date, so "should" be safe to force unwrap
    }
    
    /// Day in MM/DD/YYYY format
    var description: String {
        return "\(month)/\(day)/\(year)"
    }
    
    /// Key used for firestore map key
    var key: String {
        return "\(month):\(day):\(year)"
    }
    
    /// Date in MM/DD format
    var shortDescription: String {
        return "\(month)/\(day)"
    }
    
    var weekdayDateString: String {
        let weekday = Day.calendar.dateComponents([.weekday], from: self.date).weekday!
        let weekdayString = Day.calendar.weekdaySymbols[weekday - 1]
        
        return weekdayString + ", " + shortMonthDayString
    }
    
    /// Date in [short month name] [day] ie. `Apr 4` format
    var shortMonthDayString: String {
        let month = Day.calendar.shortMonthSymbols[self.month - 1]
        return "\(month) \(day)"
    }
    
    /// Date in [short month name] [day] ie. `Apr 4, 2020` format
    var shortMonthDayYearString: String {
        let month = Day.calendar.shortMonthSymbols[self.month - 1]
        return "\(month) \(day), \(year)"
    }
    
    var shortMonthString: String {
        return "\(Day.calendar.shortMonthSymbols[self.month - 1])"
    }
    
    /// Date in [month day, year] format, ie. `April 5, 2020`
    var fullFormattedString: String {
        let month = Day.calendar.monthSymbols[self.month - 1]
        return "\(month) \(self.day), \(self.year)"
    }
    
    /// returns true if Day contains the date, represented as a `TimeInterval` in seconds since 1970 UTC epoch
    func contains(date: Date, inTimeZone timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let startDate = DateComponents(calendar: calendar, year: self.year, month: self.month, day: self.day).date,
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return false
        }
        
        return (date >= startDate && date <= endDate)
    }
    
    /**
     - Returns: GTDay if month, day, year map to a real day, else returns nil
     
     - Parameter Month: month number from 1 - 12
     - Parameter Day: day indexed from 1
     - Parameter Year: year as actualy year (ie. 2020)
     */
    init?(month: Int, day: Int, year: Int) {
        guard let date = Day.calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        self.date = date
    }
    
    init?(fromString key: String) {
        let monthDayYear = Array(key.split(separator: ":")).map({ Int($0) }).filter({ $0 != nil }).map({ $0! })
        guard monthDayYear.count == 3 else { return nil }
        
        self.init(month: monthDayYear[0], day: monthDayYear[1], year: monthDayYear[2])
    }
    
    /**
     - Returns: GTDay (lhs) advanced by rhs number of days.
     */
    public static func + (lhs: Day, rhs: Int) -> Day {
        let newDate = Day.calendar.date(byAdding: .day, value: rhs, to: lhs.date)!
        let newDay = newDate.day(in: Day.calendar.timeZone)
        return Day(month: newDay.month, day: newDay.day, year: newDay.year)!
    }
    
    public static func < (lhs: Day, rhs: Day) -> Bool {
        if lhs.year < rhs.year { return true }
        if lhs.year > rhs.year { return false }
        
        // same year
        if lhs.month < rhs.month { return true }
        if lhs.month > rhs.month { return false }
        
        //same month
        if lhs.day < rhs.day { return true }
        return false
    }
    
    public static func == (lhs: Day, rhs: Day) -> Bool {
        return (lhs.year == rhs.year) && (lhs.month == rhs.month) && (lhs.day == rhs.day)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(year)
    }
    
    public func distance(to other: Day) -> Int {
        if self < other {
            return Day.calendar.dateComponents([.day], from: self.date, to: other.date).day!
        }
        return -Day.calendar.dateComponents([.day], from: other.date, to: self.date).day!
    }
    
    public func advanced(by n: Int) -> Day {
        return self + n
    }
}


