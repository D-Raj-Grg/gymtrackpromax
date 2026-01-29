//
//  LoadingStateView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Reusable loading state component for displaying progress indicators
struct LoadingStateView: View {
    // MARK: - Properties

    /// Optional loading message
    var message: String? = nil

    /// Size of the progress indicator
    var size: ControlSize = .regular

    /// Whether to show a card background
    var showBackground: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.component) {
            ProgressView()
                .controlSize(size)
                .tint(Color.gymPrimary)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .frame(maxWidth: showBackground ? .infinity : nil)
        .padding(showBackground ? AppSpacing.xl : 0)
        .if(showBackground) { view in
            view.background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Convenience Initializers

extension LoadingStateView {
    /// Create a simple loading indicator
    static var simple: LoadingStateView {
        LoadingStateView()
    }

    /// Create a loading indicator with message
    static func withMessage(_ message: String) -> LoadingStateView {
        LoadingStateView(message: message)
    }

    /// Create a loading indicator in a card
    static func card(message: String? = nil) -> LoadingStateView {
        LoadingStateView(message: message, showBackground: true)
    }

    /// Create a large loading indicator
    static var large: LoadingStateView {
        LoadingStateView(size: .large)
    }

    /// Create a loading indicator for data fetching
    static var loadingData: LoadingStateView {
        LoadingStateView(message: "Loading data...", size: .regular)
    }

    /// Create a loading indicator for history
    static var loadingHistory: LoadingStateView {
        LoadingStateView(message: "Loading history...")
    }

    /// Create a loading indicator for progress
    static var loadingProgress: LoadingStateView {
        LoadingStateView(message: "Calculating progress...")
    }
}

// MARK: - Full Screen Loading View

/// Full screen loading overlay
struct FullScreenLoadingView: View {
    var message: String?

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            LoadingStateView(message: message, size: .large)
        }
    }
}

// MARK: - Inline Loading View

/// Small inline loading indicator for lists and rows
struct InlineLoadingView: View {
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ProgressView()
                .controlSize(.small)
                .tint(Color.gymPrimary)

            Text("Loading...")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
    }
}

// MARK: - Preview

#Preview("Simple") {
    VStack(spacing: AppSpacing.section) {
        LoadingStateView.simple

        LoadingStateView.withMessage("Loading workouts...")

        LoadingStateView.card(message: "Fetching data...")

        LoadingStateView.large
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gymBackground)
}

#Preview("Full Screen") {
    FullScreenLoadingView(message: "Loading your data...")
}

#Preview("Inline") {
    VStack {
        InlineLoadingView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gymBackground)
}
