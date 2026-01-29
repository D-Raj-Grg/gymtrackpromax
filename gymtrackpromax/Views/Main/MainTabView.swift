//
//  MainTabView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    // MARK: - State

    @State private var selectedTab: Tab = .home

    // MARK: - Tab Enum

    enum Tab: Int, CaseIterable {
        case home
        case workout
        case history
        case progress
        case tools

        var title: String {
            switch self {
            case .home: return "Home"
            case .workout: return "Workout"
            case .history: return "History"
            case .progress: return "Progress"
            case .tools: return "Tools"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .workout: return "figure.run"
            case .history: return "calendar"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .tools: return "wrench.and.screwdriver"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            WorkoutTabView()
                .tabItem {
                    Label(Tab.workout.title, systemImage: Tab.workout.icon)
                }
                .tag(Tab.workout)

            HistoryView()
                .tabItem {
                    Label(Tab.history.title, systemImage: Tab.history.icon)
                }
                .tag(Tab.history)

            ProgressView()
                .tabItem {
                    Label(Tab.progress.title, systemImage: Tab.progress.icon)
                }
                .tag(Tab.progress)

            ToolsView()
                .tabItem {
                    Label(Tab.tools.title, systemImage: Tab.tools.icon)
                }
                .tag(Tab.tools)
        }
        .tint(Color.gymPrimary)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.tabChanged()
        }
    }

    // MARK: - Tab Bar Configuration

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.gymCard)

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.gymTextMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gymTextMuted)
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.gymPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gymPrimary)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
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
