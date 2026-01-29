//
//  WeekStartDay.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation

/// User preference for which day the week starts on
enum WeekStartDay: String, Codable, CaseIterable {
    case sunday = "sunday"
    case monday = "monday"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        }
    }

    /// Returns weekdays in display order based on this start day
    var orderedWeekdays: [Weekday] {
        switch self {
        case .sunday:
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        case .monday:
            return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        }
    }

    /// Returns weekday symbols in display order
    var orderedWeekdaySymbols: [String] {
        orderedWeekdays.map { $0.letter }
    }

    /// Smart default based on device's regional settings
    /// Calendar.current.firstWeekday returns 1 for Sunday, 2 for Monday
    /// Nepal, US, India, Japan, etc. use Sunday; Most of Europe uses Monday
    static var systemDefault: WeekStartDay {
        Calendar.current.firstWeekday == 1 ? .sunday : .monday
    }

    /// The weekday index (0=Sunday, 1=Monday, etc.) for the first day of the week
    var firstWeekdayIndex: Int {
        switch self {
        case .sunday: return 0
        case .monday: return 1
        }
    }
}
