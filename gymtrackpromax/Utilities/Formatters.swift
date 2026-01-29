//
//  Formatters.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

// MARK: - Weight Formatter

/// Formatter for displaying weight values
enum WeightFormatter {
    /// Format a weight value with unit
    /// - Parameters:
    ///   - weight: The weight value
    ///   - unit: The weight unit
    ///   - showUnit: Whether to include the unit symbol
    /// - Returns: Formatted weight string
    static func format(_ weight: Double, unit: WeightUnit, showUnit: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1

        let formatted = formatter.string(from: NSNumber(value: weight)) ?? "\(weight)"

        if showUnit {
            return "\(formatted) \(unit.symbol)"
        }
        return formatted
    }

    /// Format a weight value without decimal places
    static func formatWhole(_ weight: Double, unit: WeightUnit, showUnit: Bool = true) -> String {
        let formatted = "\(Int(weight.rounded()))"
        if showUnit {
            return "\(formatted) \(unit.symbol)"
        }
        return formatted
    }

    /// Format a volume value (typically larger numbers)
    static func formatVolume(_ volume: Double, unit: WeightUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let formatted = formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
        return "\(formatted) \(unit.symbol)"
    }
}

// MARK: - Duration Formatter

/// Formatter for displaying time durations
enum DurationFormatter {
    /// Format a duration as HH:mm:ss
    static func formatFull(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// Format a duration as mm:ss (for timers)
    static func formatTimer(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Format a duration in a human-readable way (e.g., "1h 23m")
    static func formatReadable(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "< 1m"
    }

    /// Format rest time (e.g., "90s" or "2m 30s")
    static func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let secs = seconds % 60

        if secs == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(secs)s"
    }
}

// MARK: - Date Formatter

/// Formatter for displaying dates
enum DateFormatter {
    /// Shared date formatter instances
    private static let relativeFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let fullFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let timeFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dayOfWeekFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let monthYearFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Format as relative date (Today, Yesterday, Jan 25)
    static func formatRelative(_ date: Date) -> String {
        relativeFormatter.string(from: date)
    }

    /// Format as short date (Jan 25)
    static func formatShort(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    /// Format as full date (January 25, 2026)
    static func formatFull(_ date: Date) -> String {
        fullFormatter.string(from: date)
    }

    /// Format as time (3:45 PM)
    static func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format as day of week (Monday)
    static func formatDayOfWeek(_ date: Date) -> String {
        dayOfWeekFormatter.string(from: date)
    }

    /// Format as month and year (January 2026)
    static func formatMonthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    /// Format as "Today at 3:45 PM" or "Jan 25 at 3:45 PM"
    static func formatDateAndTime(_ date: Date) -> String {
        let dateStr = formatRelative(date)
        let timeStr = formatTime(date)
        return "\(dateStr) at \(timeStr)"
    }
}

// MARK: - Number Formatter

/// Formatter for general number display
enum NumberFormatters {
    /// Format a number with thousands separator
    static func formatWithSeparator(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Format a percentage
    static func formatPercentage(_ value: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
    }

    /// Format with +/- sign
    static func formatWithSign(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format ordinal (1st, 2nd, 3rd)
    static func formatOrdinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - One Rep Max Calculator

/// Calculator for estimated one rep max
enum OneRepMaxCalculator {
    /// Calculate estimated 1RM using Epley formula
    /// - Parameters:
    ///   - weight: Weight lifted
    ///   - reps: Number of reps
    /// - Returns: Estimated 1RM
    static func calculate(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    /// Calculate weight for target reps based on 1RM
    /// - Parameters:
    ///   - oneRM: The one rep max
    ///   - targetReps: Target number of reps
    /// - Returns: Suggested weight
    static func weightForReps(oneRM: Double, targetReps: Int) -> Double {
        guard targetReps > 0 else { return 0 }
        if targetReps == 1 { return oneRM }
        return oneRM / (1 + Double(targetReps) / 30)
    }

    /// Calculate percentage of 1RM
    static func percentageOf1RM(weight: Double, oneRM: Double) -> Double {
        guard oneRM > 0 else { return 0 }
        return weight / oneRM
    }
}
