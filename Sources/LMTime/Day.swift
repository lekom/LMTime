//
//  Day.swift
//  CampsiteFinder
//
//  Created by Leko Murphy on 5/31/21.
//

import Foundation

public struct Day: Codable, Comparable, Strideable, Hashable {
    
    public static let seconds: TimeInterval = 24 * 60 * 60
    
    /// Special case that corresponds to no particular day, but comes before all other days when using comparison operator.  other operators are not supported
    public static let AnyDay = Day()
    
    /// days are counted in integer intervals
    public typealias Stride = Int
    
    /// Internal UTC calendar used in this class
    private static let calendar: Calendar = {
        var cal = Calendar.init(identifier: .gregorian)
        cal.locale = Locale.init(identifier: "en_US")
        guard let timezone = TimeZone(identifier: "UTC") else { fatalError("WTF Apple, UTC timezone no longer exists") }
        cal.timeZone = timezone
        return cal
    }()
    
    /// Date representing start of day in UTC timezone (underlying `TimeInterval` is seconds since 1970 epoch UTC)
    public private(set) var date: Date {
        didSet {
            (self.month, self.day, self.year) = (Day.calendar.component(.month, from: date),
                                                 Day.calendar.component(.day, from: date),
                                                 Day.calendar.component(.year, from: date))
        }
    }
    
    //Do Not Directly set these properties in this class, besides in initializer.  Setting date will update these
    public private(set) var month: Int
    public private(set) var day: Int
    public private(set) var year: Int
        
    /// Returns Day in user's local timezone
    public static var today: Day {
        let todayDate = Date(timeIntervalSinceNow: 0)
        let calendar = Calendar.autoupdatingCurrent
        let (month, day, year) = (calendar.component(.month, from: todayDate), calendar.component(.day, from: todayDate), calendar.component(.year, from: todayDate))
        return Day(month: month, day: day, year: year)!
    }
    
    /// Returns `TimeInterval` corresponding to seconds since UTC epoch of start of day
    public var start: TimeInterval {
        return date.timeIntervalSince1970
    }
    
    public func start(inTimeZone timeZone: TimeZone) -> Date {
        let components = DateComponents(year: self.year, month: self.month, day: self.day)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: components)! // these components come from a valid date, so "should" be safe to force unwrap
    }
    
    /// Day in MM/DD/YYYY format
    public var description: String {
        return "\(month)/\(day)/\(year)"
    }
    
    /// Key used for firestore map key
    public var key: String {
        return "\(month):\(day):\(year)"
    }
    
    /// Date in MM/DD format
    public var shortDescription: String {
        return "\(month)/\(day)"
    }
    
    /// Date in "Wednesday, Jan 20" format
    public var weekdayDateString: String {
        let weekday = Day.calendar.dateComponents([.weekday], from: self.date).weekday!
        let weekdayString = Day.calendar.weekdaySymbols[weekday - 1]
        
        return weekdayString + ", " + shortMonthDayString
    }
    
    /// Date in [short month name] [day] ie. `Apr 4` format
    public var shortMonthDayString: String {
        let month = Day.calendar.shortMonthSymbols[self.month - 1]
        return "\(month) \(day)"
    }
    
    /// Date in [short month name] [day] ie. `Apr 4, 2020` format
    public var shortMonthDayYearString: String {
        let month = Day.calendar.shortMonthSymbols[self.month - 1]
        return "\(month) \(day), \(year)"
    }
    
    public var shortMonthString: String {
        return "\(Day.calendar.shortMonthSymbols[self.month - 1])"
    }
    
    /// Date in [month day, year] format, ie. `April 5, 2020`
    public var fullFormattedString: String {
        let month = Day.calendar.monthSymbols[self.month - 1]
        return "\(month) \(self.day), \(self.year)"
    }
    
    /// returns true if Day contains the date, represented as a `TimeInterval` in seconds since 1970 UTC epoch
    public func contains(date: Date, inTimeZone timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let startDate = DateComponents(calendar: calendar, year: self.year, month: self.month, day: self.day).date,
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return false
        }
        
        return (date >= startDate && date <= endDate)
    }
    
    /**
     - Returns: Day if month, day, year map to a real day, else returns nil
     
     - Parameter Month: month number from 1 - 12
     - Parameter Day: day indexed from 1
     - Parameter Year: year as actualy year (ie. 2020)
     */
    public init?(month: Int, day: Int, year: Int) {
        guard let date = Day.calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        self.date = date
        self.month = month
        self.day = day
        self.year = year
    }
    
    init?(fromString key: String) {
        let monthDayYear = Array(key.split(separator: ":")).map({ Int($0) }).filter({ $0 != nil }).map({ $0! })
        guard monthDayYear.count == 3 else { return nil }
        
        self.init(month: monthDayYear[0], day: monthDayYear[1], year: monthDayYear[2])
    }
    
    /// only used to create `AnyDay` special Day which comes before all days and is only compatible with comparison operators
    private init() {
        self.date = Date()
        self.month = 0
        self.day = 0
        self.year = 0
    }
    
    /**
     - Returns: Day (lhs) advanced by rhs number of days.
     */
    public static func + (lhs: Day, rhs: Int) -> Day {
        guard lhs != .AnyDay else { fatalError("operator is not compatible with AnyDay Day") }
        
        let newDate = Day.calendar.date(byAdding: .day, value: rhs, to: lhs.date)!
        let newDay = Day.utcDay(from: newDate)
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
        guard self != .AnyDay, other != .AnyDay else { fatalError("Distance(to: is not compatible with AnyDay Day") }
        
        if self < other {
            return Day.calendar.dateComponents([.day], from: self.date, to: other.date).day!
        }
        return -Day.calendar.dateComponents([.day], from: other.date, to: self.date).day!
    }
    
    public func advanced(by n: Int) -> Day {
        guard self != .AnyDay else { fatalError("Advanced(by: is not compatible with AnyDay Day") }
        
        return self + n
    }
    
    public static func utcDay(from date: Date) -> Day {
        let (month, day, year) = (Self.calendar.component(.month, from: date), Self.calendar.component(.day, from: date), Self.calendar.component(.year, from: date))
        return Day(month: month, day: day, year: year)!
    }
}

