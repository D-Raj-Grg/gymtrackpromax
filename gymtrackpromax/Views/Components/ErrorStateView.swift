//
//  ErrorStateView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Reusable error state component for displaying errors with retry options
struct ErrorStateView: View {
    // MARK: - Properties

    /// Error message to display
    let message: String

    /// Optional error title (defaults to "Something Went Wrong")
    var title: String = "Something Went Wrong"

    /// Optional retry action
    var onRetry: (() -> Void)? = nil

    /// Custom icon (defaults to exclamationmark.triangle)
    var icon: String = "exclamationmark.triangle.fill"

    /// Whether to show a card background
    var showBackground: Bool = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.component) {
            // Error icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.gymError)
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.standard)

            // Retry button
            if let onRetry = onRetry {
                Button(action: {
                    HapticManager.buttonTap()
                    onRetry()
                }) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.vertical, AppSpacing.component)
                    .background(Color.gymPrimary)
                    .clipShape(Capsule())
                }
                .padding(.top, AppSpacing.small)
                .accessibilityLabel("Retry")
                .accessibilityHint("Double tap to try again")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .if(showBackground) { view in
            view.background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Convenience Initializers

extension ErrorStateView {
    /// Create an error state for network errors
    static func networkError(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            message: "Please check your internet connection and try again.",
            title: "Connection Error",
            onRetry: onRetry,
            icon: "wifi.slash"
        )
    }

    /// Create an error state for data loading errors
    static func dataError(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            message: "We couldn't load your data. Please try again.",
            title: "Failed to Load",
            onRetry: onRetry,
            icon: "exclamationmark.circle.fill"
        )
    }

    /// Create an error state for save failures
    static func saveError(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            message: "Your changes couldn't be saved. Please try again.",
            title: "Save Failed",
            onRetry: onRetry,
            icon: "xmark.circle.fill"
        )
    }

    /// Create a generic error state
    static func generic(onRetry: (() -> Void)? = nil) -> ErrorStateView {
        ErrorStateView(
            message: "An unexpected error occurred. Please try again.",
            onRetry: onRetry
        )
    }
}

// MARK: - Inline Error View

/// Small inline error indicator for forms and inputs
struct InlineErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.gymError)

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.gymError)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

// MARK: - Error Banner View

/// Banner-style error for displaying at the top of screens
struct ErrorBannerView: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.gymWarning)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.gymText)
                .lineLimit(2)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: {
                    HapticManager.buttonTap()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(Color.gymWarning.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .stroke(Color.gymWarning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Default") {
    ErrorStateView(
        message: "We couldn't load your workout data.",
        onRetry: { print("Retry tapped") }
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Static Variants") {
    ScrollView {
        VStack(spacing: AppSpacing.section) {
            ErrorStateView.networkError(onRetry: {})
            ErrorStateView.dataError(onRetry: {})
            ErrorStateView.saveError()
        }
        .padding()
    }
    .background(Color.gymBackground)
}

#Preview("Inline & Banner") {
    VStack(spacing: AppSpacing.section) {
        InlineErrorView(message: "This field is required")
            .padding()

        ErrorBannerView(
            message: "Unable to sync your data",
            onDismiss: {}
        )
        .padding()
    }
    .frame(maxHeight: .infinity)
    .background(Color.gymBackground)
}
