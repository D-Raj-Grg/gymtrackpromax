//
//  ContentView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    /// Uses @AppStorage to automatically sync with UserDefaults
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    // MARK: - Computed Properties

    /// Show main app only if onboarding is complete AND user exists
    private var shouldShowMainApp: Bool {
        hasCompletedOnboarding && !users.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background color
            Color.gymBackground
                .ignoresSafeArea()

            if shouldShowMainApp {
                // Main app content with tab navigation
                MainTabView()
            } else {
                // Onboarding flow
                OnboardingContainerView(onComplete: {
                    // @AppStorage automatically updates when UserDefaults changes
                })
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            User.self,
            WorkoutSplit.self,
            WorkoutDay.self,
            Exercise.self,
            PlannedExercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self
        ], inMemory: true)
}
