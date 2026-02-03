//
//  ContentView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import CoreSpotlight
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    /// Uses @AppStorage to automatically sync with UserDefaults
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    /// Spotlight deep-link destination
    @State private var spotlightDestination: SpotlightDestination?

    /// Workout day ID to start from Siri intent
    @State private var intentWorkoutDayId: UUID?

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
                MainTabView(
                    spotlightDestination: $spotlightDestination,
                    intentWorkoutDayId: $intentWorkoutDayId
                )
            } else {
                // Onboarding flow
                OnboardingContainerView(onComplete: {
                    // @AppStorage automatically updates when UserDefaults changes
                })
            }
        }
        .preferredColorScheme(.dark)
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            spotlightDestination = SpotlightService.shared.handleSearchResult(userActivity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startWorkoutFromIntent)) { notification in
            if let workoutDayIdString = notification.userInfo?["workoutDayId"] as? String,
               let workoutDayId = UUID(uuidString: workoutDayIdString) {
                intentWorkoutDayId = workoutDayId
            }
        }
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
