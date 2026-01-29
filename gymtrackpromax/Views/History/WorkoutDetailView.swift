//
//  WorkoutDetailView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData
import Foundation

/// Detailed view of a completed workout session
struct WorkoutDetailView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let session: WorkoutSession
    let weightUnit: WeightUnit
    let onDelete: () -> Void

    // MARK: - State

    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Summary card
                    summaryCard

                    // Exercises section
                    exercisesSection

                    // Notes section (if present)
                    if let notes = session.notes, !notes.isEmpty {
                        notesSection(notes)
                    }

                    // Delete button
                    deleteButton

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.top, AppSpacing.standard)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(session.workoutName)
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                    Text(formattedFullDate)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .alert("Delete Workout", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.component) {
            HStack(spacing: AppSpacing.section) {
                // Duration
                statItem(
                    icon: "clock.fill",
                    value: session.durationDisplay,
                    label: "Duration"
                )

                // Volume
                statItem(
                    icon: "scalemass.fill",
                    value: "\(session.totalVolumeDisplay)",
                    label: "Volume (\(weightUnit.symbol))"
                )

                // Sets
                statItem(
                    icon: "checkmark.circle.fill",
                    value: "\(session.workingSets)",
                    label: "Sets"
                )
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge))
        .padding(.horizontal, AppSpacing.standard)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.gymPrimary)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Section header
            Text("Exercises")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            // Exercise cards
            if session.sortedExerciseLogs.isEmpty {
                emptyExercisesView
            } else {
                ForEach(session.sortedExerciseLogs) { exerciseLog in
                    ExerciseDetailSection(
                        exerciseLog: exerciseLog,
                        weightUnit: weightUnit
                    )
                    .padding(.horizontal, AppSpacing.standard)
                }
            }
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundStyle(Color.gymTextMuted)

            Text("No exercises recorded")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.section)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Notes")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text(notes)
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.standard)
                .background(Color.gymCard)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "trash")
                Text("Delete Workout")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.gymError)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.standard)
            .background(Color.gymError.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.top, AppSpacing.section)
    }

    // MARK: - Actions

    private func deleteWorkout() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDelete()
        dismiss()
    }

    // MARK: - Formatting

    private var formattedFullDate: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: session.startTime)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutDetailView(
            session: {
                let session = WorkoutSession(
                    startTime: Date().addingTimeInterval(-3600),
                    endTime: Date(),
                    notes: "Great workout! Felt strong today."
                )
                return session
            }(),
            weightUnit: .kg,
            onDelete: {}
        )
    }
}
