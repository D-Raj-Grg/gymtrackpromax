//
//  WorkoutSummaryView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    // MARK: - Properties

    let session: WorkoutSession
    let achievedPRs: [PRInfo]
    @Binding var notes: String
    let weightUnit: WeightUnit
    let onSave: () -> Void

    // MARK: - State

    @State private var showConfetti = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Celebration header
                celebrationHeader

                // Stats grid
                statsGrid

                // PRs section (if any)
                if !achievedPRs.isEmpty {
                    prsSection
                }

                // Notes field
                notesSection

                // Save button
                Button(action: {
                    HapticManager.workoutComplete()
                    onSave()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Workout")
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal, AppSpacing.standard)
                .accessibleButton(label: "Save Workout", hint: "Double tap to save and close")

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.top, AppSpacing.section)
        }
        .background(Color.gymBackground)
        .onAppear {
            // Trigger celebration animation
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showConfetti = true
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: AppSpacing.standard) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.gymSuccess.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.gymSuccess)
            }
            .scaleEffect(showConfetti ? 1 : 0.5)
            .opacity(showConfetti ? 1 : 0)

            // Title
            Text("Workout Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            // Workout name
            Text(session.workoutName)
                .font(.headline)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.standard) {
            // Duration
            StatCard(
                icon: "clock.fill",
                value: session.durationDisplay,
                label: "Duration",
                color: Color.gymPrimary
            )

            // Total Volume
            StatCard(
                icon: "scalemass.fill",
                value: "\(session.totalVolumeDisplay) \(weightUnit.symbol)",
                label: "Volume",
                color: Color.gymAccent
            )

            // Sets
            StatCard(
                icon: "number.circle.fill",
                value: "\(session.workingSets)",
                label: "Working Sets",
                color: Color.gymSuccess
            )

            // Exercises
            StatCard(
                icon: "dumbbell.fill",
                value: "\(session.exercisesCompleted)",
                label: "Exercises",
                color: Color.gymWarning
            )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - PRs Section

    private var prsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.gymWarning)
                Text("Personal Records")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
            }
            .padding(.horizontal, AppSpacing.standard)

            VStack(spacing: AppSpacing.small) {
                ForEach(achievedPRs) { pr in
                    PRRow(pr: pr, weightUnit: weightUnit)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            TextField("Add workout notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(AppSpacing.standard)
                .background(Color.gymCard)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input))
                .foregroundStyle(Color.gymText)
        }
        .padding(.horizontal, AppSpacing.standard)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }
}

// MARK: - PR Row

struct PRRow: View {
    let pr: PRInfo
    let weightUnit: WeightUnit

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Star icon
            Image(systemName: "star.fill")
                .font(.headline)
                .foregroundStyle(Color.gymWarning)

            // Exercise name
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
                    .lineLimit(1)

                Text(pr.type.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            // Value
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)

                // Improvement
                Text("+\(formattedImprovement)")
                    .font(.caption)
                    .foregroundStyle(Color.gymSuccess)
            }
        }
        .padding(AppSpacing.component)
        .background(Color.gymWarning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
    }

    private var formattedValue: String {
        if pr.value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(pr.value)) \(weightUnit.symbol)"
        }
        return String(format: "%.1f %@", pr.value, weightUnit.symbol)
    }

    private var formattedImprovement: String {
        if pr.improvement.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(pr.improvement)) \(weightUnit.symbol)"
        }
        return String(format: "%.1f %@", pr.improvement, weightUnit.symbol)
    }
}

// MARK: - Preview

struct WorkoutSummaryPreview: View {
    @State private var notes = ""

    var body: some View {
        let session = WorkoutSession(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        )

        let prs = [
            PRInfo(
                exerciseName: "Bench Press",
                type: .estimated1RM,
                value: 110,
                previousValue: 105,
                improvement: 5
            )
        ]

        WorkoutSummaryView(
            session: session,
            achievedPRs: prs,
            notes: $notes,
            weightUnit: .kg,
            onSave: {}
        )
    }
}

#Preview {
    WorkoutSummaryPreview()
        .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, SetLog.self], inMemory: true)
}
