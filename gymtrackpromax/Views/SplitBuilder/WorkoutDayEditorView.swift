//
//  WorkoutDayEditorView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// View to edit single workout day with exercises
struct WorkoutDayEditorView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Query

    @Query private var users: [User]

    // MARK: - Properties

    @Bindable var viewModel: SplitBuilderViewModel
    let dayIndex: Int

    // MARK: - State

    @State private var showingExercisePicker: Bool = false
    @State private var showingExerciseLibrary: Bool = false
    @State private var showingExerciseEditor: Bool = false
    @State private var editingExerciseIndex: Int?
    @State private var showingDiscardAlert: Bool = false
    @State private var isReorderingExercises: Bool = false

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        guard dayIndex < viewModel.workoutDays.count else { return false }
        let original = viewModel.workoutDays[dayIndex]
        return original.name != viewModel.currentDayName ||
               original.exercises != viewModel.currentDayExercises ||
               Set(original.scheduledWeekdays) != Set(viewModel.currentDayScheduledWeekdays)
    }

    private var isValid: Bool {
        !viewModel.currentDayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Weekdays ordered based on user's saved week start day preference
    private var orderedWeekdays: [Weekday] {
        (users.first?.weekStartDay ?? .monday).orderedWeekdays
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Day Name Section
                        dayNameSection

                        // Scheduled Days Section
                        scheduledDaysSection

                        // Exercises Section
                        exercisesSection

                        // Stats Summary
                        if !viewModel.currentDayExercises.isEmpty {
                            statsSummary
                        }

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
                .scrollDisabled(isReorderingExercises)
            }
            .navigationTitle("Edit Day")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Ensure day data is loaded when view appears
                viewModel.startEditingDay(at: dayIndex)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            viewModel.cancelDayEdits()
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        saveDayEdits()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? Color.gymPrimary : Color.gymTextMuted)
                    .disabled(!isValid)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.cancelDayEdits()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercises in
                    viewModel.addExercisesToCurrentDay(exercises)
                }
            }
            .sheet(isPresented: $showingExerciseLibrary) {
                ExerciseLibraryView(
                    onExerciseSelected: { exercise in
                        viewModel.addExercisesToCurrentDay([exercise])
                    },
                    isSelectionMode: true
                )
            }
            .sheet(isPresented: $showingExerciseEditor) {
                if let index = editingExerciseIndex {
                    ExerciseConfigSheet(
                        exercise: $viewModel.currentDayExercises[index],
                        onSave: {
                            showingExerciseEditor = false
                            editingExerciseIndex = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Day Name Section

    private var dayNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Day Name")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            TextField("e.g., Push, Leg Day, Upper Body", text: $viewModel.currentDayName)
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
                            viewModel.currentDayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gymWarning.opacity(0.5)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Scheduled Days Section

    private var scheduledDaysSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Scheduled Days")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            Text("Which days of the week should this workout be performed?")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            HStack(spacing: AppSpacing.small) {
                ForEach(orderedWeekdays, id: \.rawValue) { weekday in
                    DayToggleButton(
                        dayLetter: weekday.letter,
                        isSelected: viewModel.currentDayScheduledWeekdays.contains(weekday.rawValue),
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            toggleWeekday(weekday.rawValue)
                        }
                    )
                }
            }
            .padding(.top, AppSpacing.xs)

            if !viewModel.currentDayScheduledWeekdays.isEmpty {
                Text(scheduledDaysDisplayText)
                    .font(.caption)
                    .foregroundStyle(Color.gymPrimary)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    private var scheduledDaysDisplayText: String {
        // Display selected days in the user's preferred week order
        let selectedSet = Set(viewModel.currentDayScheduledWeekdays)
        let dayNames = orderedWeekdays
            .filter { selectedSet.contains($0.rawValue) }
            .map { $0.shortName }
        return dayNames.joined(separator: ", ")
    }

    private func toggleWeekday(_ weekday: Int) {
        if let index = viewModel.currentDayScheduledWeekdays.firstIndex(of: weekday) {
            viewModel.currentDayScheduledWeekdays.remove(at: index)
        } else {
            viewModel.currentDayScheduledWeekdays.append(weekday)
        }
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("Exercises")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                // Browse Library button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingExerciseLibrary = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "books.vertical")
                        Text("Browse")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymTextMuted)
                }

                // Add exercises button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingExercisePicker = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymPrimary)
                }
            }
            .padding(.horizontal, AppSpacing.standard)

            if viewModel.currentDayExercises.isEmpty {
                emptyExercisesState
            } else {
                exercisesList
            }
        }
    }

    // MARK: - Empty Exercises State

    private var emptyExercisesState: some View {
        VStack(spacing: AppSpacing.component) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundStyle(Color.gymTextMuted)

            Text("No exercises added yet")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingExercisePicker = true
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercises")
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

    // MARK: - Exercises List

    private var exercisesList: some View {
        ReorderableForEach(
            items: viewModel.currentDayExercises,
            isReordering: $isReorderingExercises,
            onMove: { source, destination in
                viewModel.moveExercisesInCurrentDay(from: source, to: destination)
            }
        ) { exercise, dragHandle in
            SwipeToDeleteContainer(isDisabled: isReorderingExercises, onDelete: {
                guard let index = viewModel.currentDayExercises.firstIndex(where: { $0.id == exercise.id }) else { return }
                withAnimation(AppAnimation.spring) {
                    viewModel.removeExerciseFromCurrentDay(at: index)
                }
            }) {
                PlannedExerciseRow(
                    exercise: exercise,
                    onTap: {
                        guard let index = viewModel.currentDayExercises.firstIndex(where: { $0.id == exercise.id }) else { return }
                        editingExerciseIndex = index
                        showingExerciseEditor = true
                    },
                    onDelete: nil,
                    showDragHandle: false,
                    leadingAccessory: dragHandle
                )
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            HStack(spacing: AppSpacing.component) {
                statCard(
                    icon: "dumbbell.fill",
                    value: "\(viewModel.currentDayExercises.count)",
                    label: "Exercises"
                )

                statCard(
                    icon: "square.stack.fill",
                    value: "\(viewModel.currentDayExercises.reduce(0) { $0 + $1.targetSets })",
                    label: "Total Sets"
                )

                statCard(
                    icon: "clock",
                    value: "~\(viewModel.currentDayExercises.reduce(0) { $0 + $1.targetSets } * 3)",
                    label: "Minutes"
                )
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
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

    // MARK: - Save

    private func saveDayEdits() {
        viewModel.saveCurrentDayEdits()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Exercise Config Sheet

struct ExerciseConfigSheet: View {
    @Binding var exercise: DraftPlannedExercise
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var targetSets: Int = 3
    @State private var targetRepsMin: Int = 8
    @State private var targetRepsMax: Int = 12
    @State private var restSeconds: Int = 90
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Exercise Header
                        exerciseHeader

                        // Configuration
                        configSection

                        // Notes
                        notesSection

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
            .navigationTitle("Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymPrimary)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var exerciseHeader: some View {
        VStack(spacing: AppSpacing.small) {
            Text(exercise.exerciseName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text(exercise.primaryMuscle.displayName)
                .font(.subheadline)
                .foregroundStyle(Color.gymPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.component)
    }

    private var configSection: some View {
        VStack(spacing: AppSpacing.component) {
            // Sets
            configRow(title: "Sets", value: $targetSets, range: 1...10, suffix: "sets")

            // Rep Range
            HStack(spacing: AppSpacing.component) {
                configRow(title: "Min Reps", value: $targetRepsMin, range: 1...100, suffix: "reps")
                configRow(title: "Max Reps", value: $targetRepsMax, range: 1...100, suffix: "reps")
            }

            // Rest Time
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Rest Time")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.small) {
                        ForEach([30, 60, 90, 120, 180, 240, 300], id: \.self) { seconds in
                            restTimeChip(seconds)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    private func configRow(title: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)

            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue > range.lowerBound ? Color.gymPrimary : Color.gymTextMuted)
                }
                .disabled(value.wrappedValue <= range.lowerBound)

                Text("\(value.wrappedValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
                    .frame(minWidth: 40)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value.wrappedValue < range.upperBound ? Color.gymPrimary : Color.gymTextMuted)
                }
                .disabled(value.wrappedValue >= range.upperBound)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }
    }

    private func restTimeChip(_ seconds: Int) -> some View {
        let isSelected = restSeconds == seconds

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            restSeconds = seconds
        } label: {
            Text(formatRestTime(seconds))
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.component)
                .padding(.vertical, AppSpacing.small)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.gymPrimary : Color.gymCard)
                )
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Notes")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)

            TextField("Optional notes...", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.gymText)
                .lineLimit(2...4)
                .padding(AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .fill(Color.gymCard)
                )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(minutes)m"
            }
            return "\(minutes):\(String(format: "%02d", secs))"
        }
        return "\(seconds)s"
    }

    private func loadCurrentValues() {
        targetSets = exercise.targetSets
        targetRepsMin = exercise.targetRepsMin
        targetRepsMax = exercise.targetRepsMax
        restSeconds = exercise.restSeconds
        notes = exercise.notes ?? ""
    }

    private func saveChanges() {
        exercise.targetSets = targetSets
        exercise.targetRepsMin = min(targetRepsMin, targetRepsMax)
        exercise.targetRepsMax = max(targetRepsMin, targetRepsMax)
        exercise.restSeconds = restSeconds
        exercise.notes = notes.isEmpty ? nil : notes
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSave()
    }
}

// MARK: - Preview

#Preview {
    let viewModel = SplitBuilderViewModel(modelContext: try! ModelContainer(for: Exercise.self).mainContext)
    viewModel.workoutDays = [
        DraftWorkoutDay(name: "Push Day", dayOrder: 0, exercises: [])
    ]
    viewModel.startEditingDay(at: 0)

    return WorkoutDayEditorView(viewModel: viewModel, dayIndex: 0)
        .modelContainer(for: [Exercise.self], inMemory: true)
}
