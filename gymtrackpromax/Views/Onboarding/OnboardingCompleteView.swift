//
//  OnboardingCompleteView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Final onboarding screen with celebration and summary
struct OnboardingCompleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: OnboardingViewModel

    var onComplete: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var isLoading: Bool = false
    @State private var hasCompletedSetup: Bool = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            // Celebration icon
            celebrationIcon

            // Welcome message
            welcomeMessage

            // Summary card
            summaryCard

            Spacer()

            // Action buttons
            actionButtons
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.bottom, AppSpacing.large)
        .opacity(contentOpacity)
        .onAppear {
            startAnimations()
            setupWorkout()
        }
        .alert("Setup Error", isPresented: .constant(errorMessage != nil)) {
            Button("Try Again") {
                errorMessage = nil
                setupWorkout()
            }
            Button("Skip") {
                errorMessage = nil
                onComplete()
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Celebration Icon

    private var celebrationIcon: some View {
        ZStack {
            // Outer ring animation
            Circle()
                .stroke(Color.gymSuccess.opacity(0.3), lineWidth: 3)
                .frame(width: 140, height: 140)
                .scaleEffect(iconScale * 1.2)

            // Inner circle
            Circle()
                .fill(Color.gymSuccess.opacity(0.15))
                .frame(width: 120, height: 120)

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.gymSuccess)
                .scaleEffect(iconScale)
        }
        .opacity(iconOpacity)
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        VStack(spacing: AppSpacing.small) {
            Text("You're all set!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Welcome, \(viewModel.userName)!")
                .font(.title3)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.standard) {
            // Split info
            SummaryRow(
                icon: "figure.strengthtraining.traditional",
                title: "Workout Split",
                value: viewModel.selectedSplit.displayName
            )

            Divider()
                .background(Color.gymBorder)

            // Days per week
            SummaryRow(
                icon: "calendar",
                title: "Training Days",
                value: "\(viewModel.selectedDaysCount) days per week"
            )

            Divider()
                .background(Color.gymBorder)

            // Start date
            SummaryRow(
                icon: "clock",
                title: "Start Date",
                value: viewModel.startDateFormatted
            )
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.component) {
            // Start workout button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onComplete()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(Color.gymText)
                } else {
                    Text("Start Your First Workout")
                }
            }
            .primaryButtonStyle(isEnabled: hasCompletedSetup && !isLoading)
            .disabled(!hasCompletedSetup || isLoading)

            // Explore app button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onComplete()
            } label: {
                Text("Explore the App")
            }
            .secondaryButtonStyle()
            .disabled(isLoading)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Icon scale and fade in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Content fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            contentOpacity = 1.0
        }
    }

    // MARK: - Setup

    private func setupWorkout() {
        guard !hasCompletedSetup else { return }

        isLoading = true

        Task {
            do {
                try await viewModel.completeOnboarding(context: modelContext)
                await MainActor.run {
                    hasCompletedSetup = true
                    isLoading = false
                    // Haptic feedback for success
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create your workout plan. Please try again."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.gymPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.gymText)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        OnboardingCompleteView(
            viewModel: {
                let vm = OnboardingViewModel()
                vm.userName = "Alex"
                vm.selectedSplit = .ppl
                vm.setDefaultWeekdays()
                return vm
            }(),
            onComplete: {}
        )
    }
    .preferredColorScheme(.dark)
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
