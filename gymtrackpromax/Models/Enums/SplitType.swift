//
//  SplitType.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// Type of workout split
enum SplitType: String, Codable, CaseIterable {
    case ppl = "ppl"
    case upperLower = "upperLower"
    case ulPpl = "ulPpl"
    case pplUl = "pplUl"
    case broSplit = "broSplit"
    case fullBody = "fullBody"
    case arnoldSplit = "arnoldSplit"
    case custom = "custom"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .ppl:
            return "Push Pull Legs"
        case .upperLower:
            return "Upper/Lower"
        case .ulPpl:
            return "Upper/Lower + PPL"
        case .pplUl:
            return "PPL + Upper/Lower"
        case .broSplit:
            return "Bro Split"
        case .fullBody:
            return "Full Body"
        case .arnoldSplit:
            return "Arnold Split"
        case .custom:
            return "Custom"
        }
    }

    /// Short name for compact display
    var shortName: String {
        switch self {
        case .ppl:
            return "PPL"
        case .upperLower:
            return "U/L"
        case .ulPpl:
            return "UL+PPL"
        case .pplUl:
            return "PPL+UL"
        case .broSplit:
            return "Bro"
        case .fullBody:
            return "Full"
        case .arnoldSplit:
            return "Arnold"
        case .custom:
            return "Custom"
        }
    }

    /// Description of the split
    var description: String {
        switch self {
        case .ppl:
            return "Push, Pull, and Legs on separate days. Great for intermediate to advanced lifters."
        case .upperLower:
            return "Alternate between upper and lower body days. Good balance of frequency and recovery."
        case .ulPpl:
            return "Combines Upper/Lower with Push Pull Legs. Best of both worlds in a weekly rotation."
        case .pplUl:
            return "Starts with Push Pull Legs, ends with Upper/Lower. Unique hybrid approach."
        case .broSplit:
            return "One muscle group per day. Classic bodybuilding approach."
        case .fullBody:
            return "Train your entire body each session. Ideal for beginners or busy schedules."
        case .arnoldSplit:
            return "Chest/Back, Shoulders/Arms, Legs. High volume 6-day split."
        case .custom:
            return "Create your own custom workout split."
        }
    }

    /// Number of workout days per week
    var daysPerWeek: Int {
        switch self {
        case .ppl:
            return 6
        case .upperLower:
            return 4
        case .ulPpl:
            return 5
        case .pplUl:
            return 5
        case .broSplit:
            return 5
        case .fullBody:
            return 3
        case .arnoldSplit:
            return 6
        case .custom:
            return 0
        }
    }

    /// Badge text for UI (e.g., "Most Popular")
    var badge: String? {
        switch self {
        case .ppl:
            return "Most Popular"
        case .upperLower:
            return nil
        case .ulPpl:
            return "Hybrid"
        case .pplUl:
            return "Hybrid"
        case .broSplit:
            return "Classic"
        case .fullBody:
            return "Beginner Friendly"
        case .arnoldSplit:
            return "Advanced"
        case .custom:
            return nil
        }
    }

    /// Recommended experience level
    var recommendedLevel: ExperienceLevel {
        switch self {
        case .ppl:
            return .intermediate
        case .upperLower:
            return .intermediate
        case .ulPpl:
            return .intermediate
        case .pplUl:
            return .intermediate
        case .broSplit:
            return .intermediate
        case .fullBody:
            return .beginner
        case .arnoldSplit:
            return .advanced
        case .custom:
            return .intermediate
        }
    }

    /// Default day names for this split
    var defaultDayNames: [String] {
        switch self {
        case .ppl:
            return ["Push", "Pull", "Legs", "Push", "Pull", "Legs"]
        case .upperLower:
            return ["Upper", "Lower", "Upper", "Lower"]
        case .ulPpl:
            return ["Upper", "Lower", "Push", "Pull", "Legs"]
        case .pplUl:
            return ["Push", "Pull", "Legs", "Upper", "Lower"]
        case .broSplit:
            return ["Chest", "Back", "Shoulders", "Arms", "Legs"]
        case .fullBody:
            return ["Full Body A", "Full Body B", "Full Body C"]
        case .arnoldSplit:
            return ["Chest & Back", "Shoulders & Arms", "Legs", "Chest & Back", "Shoulders & Arms", "Legs"]
        case .custom:
            return []
        }
    }
}
