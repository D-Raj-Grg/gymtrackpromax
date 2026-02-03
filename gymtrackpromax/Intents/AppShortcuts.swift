//
//  AppShortcuts.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import AppIntents

/// Registers GymTrack Pro shortcuts with the system
/// These appear in the Shortcuts app and can be invoked by Siri
struct AppShortcuts: AppShortcutsProvider {

    // MARK: - App Shortcuts

    static var appShortcuts: [AppShortcut] {
        // "What's my workout today?"
        AppShortcut(
            intent: GetTodayWorkoutIntent(),
            phrases: [
                "What's my workout today in \(.applicationName)",
                "What workout do I have today in \(.applicationName)",
                "Show me today's workout in \(.applicationName)",
                "What's on my gym schedule in \(.applicationName)",
                "What should I train today in \(.applicationName)"
            ],
            shortTitle: "Today's Workout",
            systemImageName: "calendar"
        )

        // "Start my workout"
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start my workout in \(.applicationName)",
                "Start workout in \(.applicationName)",
                "Begin my workout in \(.applicationName)",
                "Let's workout in \(.applicationName)",
                "Start \(\.$workout) in \(.applicationName)"
            ],
            shortTitle: "Start Workout",
            systemImageName: "figure.run"
        )

        // "Log a set"
        AppShortcut(
            intent: LogSetIntent(),
            phrases: [
                "Log a set in \(.applicationName)",
                "Add a set in \(.applicationName)",
                "Record a set in \(.applicationName)"
            ],
            shortTitle: "Log Set",
            systemImageName: "plus.circle"
        )
    }
}
