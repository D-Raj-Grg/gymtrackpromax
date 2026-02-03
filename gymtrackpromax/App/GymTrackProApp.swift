//
//  GymTrackProApp.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import WatchConnectivity
import WidgetKit

@main
struct GymTrackProApp: App {
    // MARK: - Notification Delegate

    private let notificationDelegate = NotificationDelegate()

    // MARK: - SwiftData Container

    var sharedModelContainer: ModelContainer = {
        // Migrate existing store to App Group container on first launch
        SharedModelContainer.migrateStoreIfNeeded()

        do {
            return try SharedModelContainer.makeContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - State

    @State private var isExercisesLoaded = false
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    // MARK: - Initialization

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isExercisesLoaded {
                    ContentView()
                } else {
                    // Show loading splash while seeding exercises
                    AppLoadingView()
                }
            }
            .task {
                await seedExercisesIfNeeded()
                isExercisesLoaded = true

                // Activate Watch connectivity after exercises are loaded
                activateWatchConnectivity()
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetUpdateService.reloadAllTimelines()

                // Send updated data to Watch when app becomes active
                PhoneConnectivityService.shared.sendTodayWorkout()
            }
        }
    }

    // MARK: - Watch Connectivity

    /// Activates Watch connectivity service
    private func activateWatchConnectivity() {
        PhoneConnectivityService.shared.activate(modelContext: sharedModelContainer.mainContext)
    }

    // MARK: - Seed Data

    /// Seeds the exercise database on first launch
    private func seedExercisesIfNeeded() async {
        let context = sharedModelContainer.mainContext

        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            // Seed exercises from JSON - await completion before continuing
            await ExerciseService.shared.seedExercises(context: context)
        } else {
            // Add any new built-in exercises that were added in app updates
            await ExerciseService.shared.seedMissingExercises(context: context)
        }
    }
}

// MARK: - App Loading View

/// Simple loading view shown while seeding exercise database
private struct AppLoadingView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.section) {
                // Logo
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.gymPrimary)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name
                Text("GymTrack Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
                    .opacity(logoOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}
