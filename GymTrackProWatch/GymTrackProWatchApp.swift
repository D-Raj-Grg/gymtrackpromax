//
//  GymTrackProWatchApp.swift
//  GymTrackProWatch
//
//  Apple Watch companion app for GymTrack Pro.
//

import SwiftUI
import WatchConnectivity

@main
struct GymTrackProWatchApp: App {
    // MARK: - State

    @StateObject private var viewModel = WatchWorkoutViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            WatchWorkoutListView()
                .environmentObject(viewModel)
        }
    }
}
