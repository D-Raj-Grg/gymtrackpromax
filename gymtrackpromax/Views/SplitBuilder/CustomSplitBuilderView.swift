//
//  CustomSplitBuilderView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Wrapper for day editing to enable item-based sheet presentation
private struct EditingDayItem: Identifiable {
    let id = UUID()
    let index: Int
}

/// Main split editor with day list and save functionality
struct CustomSplitBuilderView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var users: [User]

    // MARK: - Properties

    var existingSplit: WorkoutSplit?
    var templateType: SplitType?

    // MARK: - State

    @State private var viewModel: SplitBuilderViewModel?
    @State private var editingDayItem: EditingDayItem?
    @State private var showingDiscardAlert: Bool = false
    @State private var showingDeleteDayAlert: Bool = false
    @State private var dayToDeleteIndex: Int?
    @State private var isSaving: Bool = false

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var canSave: Bool {
        guard let viewModel = viewModel else { return false }
        return !viewModel.splitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.workoutDays.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: AppSpacing.section) {
                            // Split Name Section
                            splitNameSection(viewModel: viewModel)

                            // Workout Days Section
                            workoutDaysSection(viewModel: viewModel)

                            // Summary Section
                            if !viewModel.workoutDays.isEmpty {
                                summarySection(viewModel: viewModel)
                            }

                            Spacer(minLength: AppSpacing.xl)
                        }
                        .padding(.top, AppSpacing.standard)
                    }
                } else {
                    ProgressView()
                        .tint(Color.gymPrimary)
                }
            }
            .navigationTitle(existingSplit != nil ? "Edit Split" : "Create Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        handleCancel()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let viewModel = viewModel {
                            saveSplit(viewModel: viewModel)
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.gymPrimary)
                        } else {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(canSave ? Color.gymPrimary : Color.gymTextMuted)
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Delete Day?", isPresented: $showingDeleteDayAlert) {
                Button("Delete", role: .destructive) {
                    if let index = dayToDeleteIndex {
                        withAnimation(AppAnimation.spring) {
                            viewModel?.removeWorkoutDay(at: index)
                        }
                    }
                    dayToDeleteIndex = nil
                }
                Button("Cancel", role: .cancel) {
                    dayToDeleteIndex = nil
                }
            } message: {
                Text("This will remove the day and all its exercises.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showingError ?? false },
                set: { viewModel?.showingError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel?.errorMessage ?? "An error occurred")
            }
            .alert("Remove Exercises with Progress?", isPresented: Binding(
                get: { viewModel?.showingInProgressConflictAlert ?? false },
                set: { viewModel?.showingInProgressConflictAlert = $0 }
            )) {
                Button("Remove Progress", role: .destructive) {
                    guard let viewModel = viewModel else { return }
                    do {
                        try viewModel.confirmAndSaveSplit()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } catch {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        viewModel.showError(error.localizedDescription)
                    }
                    isSaving = false
                }
                Button("Cancel", role: .cancel) {
                    isSaving = false
                }
            } message: {
                Text(viewModel?.conflictAlertMessage ?? "Some exercises have logged progress.")
            }
            .sheet(item: $editingDayItem) { item in
                if let viewModel = viewModel {
                    WorkoutDayEditorView(viewModel: viewModel, dayIndex: item.index)
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
    }

    // MARK: - Split Name Section

    private func splitNameSection(viewModel: SplitBuilderViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Split Name")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            TextField("e.g., My PPL, Custom Split", text: Binding(
                get: { viewModel.splitName },
                set: { viewModel.splitName = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(Color.gymText)
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                    .fill(Color.gymCardHover)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                    .strokeBorder(
                        viewModel.splitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.gymWarning.opacity(0.5)
                            : Color.clear,
                        lineWidth: 1
                    )
            )

            // Split type info
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("This split will be saved as a custom split")
                    .font(.caption)
            }
            .foregroundStyle(Color.gymTextMuted)
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Workout Days Section

    private func workoutDaysSection(viewModel: SplitBuilderViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("Workout Days")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                if viewModel.workoutDays.count < 7 {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(AppAnimation.spring) {
                            viewModel.addWorkoutDay()
                        }
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "plus")
                            Text("Add Day")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymPrimary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.standard)

            if viewModel.workoutDays.isEmpty {
                emptyDaysState(viewModel: viewModel)
            } else {
                daysList(viewModel: viewModel)
            }
        }
    }

    // MARK: - Empty Days State

    private func emptyDaysState(viewModel: SplitBuilderViewModel) -> some View {
        VStack(spacing: AppSpacing.component) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.gymTextMuted)

            Text("No workout days yet")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(AppAnimation.spring) {
                    viewModel.addWorkoutDay()
                }
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Day")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.section)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Days List

    private func daysList(viewModel: SplitBuilderViewModel) -> some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(Array(viewModel.workoutDays.enumerated()), id: \.element.id) { index, day in
                SwipeToDeleteContainer(onDelete: {
                    if day.exercises.isEmpty {
                        withAnimation(AppAnimation.spring) {
                            viewModel.removeWorkoutDay(at: index)
                        }
                    } else {
                        dayToDeleteIndex = index
                        showingDeleteDayAlert = true
                    }
                }) {
                    WorkoutDayCard(
                        day: day,
                        dayNumber: index + 1,
                        onTap: {
                            viewModel.startEditingDay(at: index)
                            editingDayItem = EditingDayItem(index: index)
                        },
                        onDelete: nil,
                        showDragHandle: false
                    )
                }
                .padding(.horizontal, AppSpacing.standard)
            }

            // Max days info
            if viewModel.workoutDays.count >= 7 {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Maximum of 7 days per split")
                        .font(.caption)
                }
                .foregroundStyle(Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.standard)
            }
        }
    }

    // MARK: - Summary Section

    private func summarySection(viewModel: SplitBuilderViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            HStack(spacing: AppSpacing.component) {
                summaryCard(
                    icon: "calendar",
                    value: "\(viewModel.workoutDays.count)",
                    label: "Days/Week"
                )

                summaryCard(
                    icon: "dumbbell.fill",
                    value: "\(viewModel.workoutDays.reduce(0) { $0 + $1.exercises.count })",
                    label: "Exercises"
                )

                summaryCard(
                    icon: "square.stack.fill",
                    value: "\(viewModel.workoutDays.reduce(0) { $0 + $1.totalSets })",
                    label: "Total Sets"
                )
            }
            .padding(.horizontal, AppSpacing.standard)

            // Validation messages
            validationMessages(viewModel: viewModel)
        }
    }

    private func summaryCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.gymPrimary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    private func validationMessages(viewModel: SplitBuilderViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Days without exercises
            let emptyDays = viewModel.workoutDays.filter { $0.exercises.isEmpty }
            if !emptyDays.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.gymWarning)

                    Text("\(emptyDays.count) day\(emptyDays.count == 1 ? "" : "s") without exercises")
                        .font(.caption)
                        .foregroundStyle(Color.gymWarning)
                }
            }

            // Days without names
            let unnamedDays = viewModel.workoutDays.filter { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !unnamedDays.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.gymWarning)

                    Text("\(unnamedDays.count) day\(unnamedDays.count == 1 ? "" : "s") need\(unnamedDays.count == 1 ? "s" : "") a name")
                        .font(.caption)
                        .foregroundStyle(Color.gymWarning)
                }
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = SplitBuilderViewModel(modelContext: modelContext)

            if let split = existingSplit {
                viewModel?.loadSplit(split)
            } else if let template = templateType, template != .custom {
                // Load template with user's week start preference
                let weekStartDay = currentUser?.weekStartDay ?? .monday
                viewModel?.loadTemplate(template, weekStartDay: weekStartDay)
            }
        }
    }

    private func handleCancel() {
        if viewModel?.hasUnsavedChanges == true {
            showingDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveSplit(viewModel: SplitBuilderViewModel) {
        guard let user = currentUser else {
            viewModel.showError("No user found")
            return
        }

        isSaving = true

        do {
            try viewModel.saveSplit(for: user)
            // If conflict alert is showing, don't dismiss yet — wait for user confirmation
            if viewModel.showingInProgressConflictAlert {
                return
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            viewModel.showError(error.localizedDescription)
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview("New Split") {
    CustomSplitBuilderView()
        .modelContainer(for: [
            User.self,
            WorkoutSplit.self,
            WorkoutDay.self,
            Exercise.self,
            PlannedExercise.self
        ], inMemory: true)
}
