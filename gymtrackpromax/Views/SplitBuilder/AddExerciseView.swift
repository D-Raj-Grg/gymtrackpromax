//
//  AddExerciseView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Form to create a custom exercise
struct AddExerciseView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    var onExerciseCreated: ((Exercise) -> Void)?

    // MARK: - State

    @State private var name: String = ""
    @State private var primaryMuscle: MuscleGroup = .chest
    @State private var secondaryMuscles: Set<MuscleGroup> = []
    @State private var equipment: Equipment = .barbell
    @State private var instructions: String = ""

    @State private var isSaving: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Exercise Name
                        nameSection

                        // Primary Muscle
                        primaryMuscleSection

                        // Secondary Muscles
                        secondaryMusclesSection

                        // Equipment
                        equipmentSection

                        // Instructions
                        instructionsSection

                        // Save Button
                        saveButton

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        formGroup(title: "Exercise Name", required: true) {
            TextField("e.g., Incline Cable Fly", text: $name)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.gymText)
                .padding(AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .fill(Color.gymCardHover)
                )
                .accessibilityLabel("Exercise name")
        }
    }

    // MARK: - Primary Muscle Section

    private var primaryMuscleSection: some View {
        formGroup(title: "Primary Muscle", required: true) {
            VStack(spacing: AppSpacing.small) {
                ForEach(MuscleGroup.allCases, id: \.rawValue) { muscle in
                    muscleOption(muscle, isSelected: primaryMuscle == muscle) {
                        primaryMuscle = muscle
                        // Remove from secondary if selected as primary
                        secondaryMuscles.remove(muscle)
                    }
                }
            }
        }
    }

    // MARK: - Secondary Muscles Section

    private var secondaryMusclesSection: some View {
        formGroup(title: "Secondary Muscles", subtitle: "Optional - select muscles that assist in this exercise") {
            MuscleGroupMultiSelector(
                selectedMuscles: Binding(
                    get: { secondaryMuscles },
                    set: { newValue in
                        // Don't allow primary muscle in secondary
                        var filtered = newValue
                        filtered.remove(primaryMuscle)
                        secondaryMuscles = filtered
                    }
                )
            )
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        formGroup(title: "Equipment", required: true) {
            VStack(spacing: AppSpacing.small) {
                ForEach(Equipment.allCases, id: \.rawValue) { equip in
                    equipmentOption(equip, isSelected: equipment == equip) {
                        equipment = equip
                    }
                }
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        formGroup(title: "Instructions", subtitle: "Optional - add form cues or notes") {
            TextField("e.g., Keep elbows slightly bent...", text: $instructions, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.gymText)
                .lineLimit(3...6)
                .padding(AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .fill(Color.gymCardHover)
                )
                .accessibilityLabel("Exercise instructions")
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            saveExercise()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(Color.gymText)
                        .scaleEffect(0.9)
                } else {
                    Text("Create Exercise")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(isValid ? Color.gymPrimary : Color.gymCardHover)
            )
            .foregroundStyle(isValid ? Color.gymText : Color.gymTextMuted)
        }
        .disabled(!isValid || isSaving)
        .padding(.horizontal, AppSpacing.standard)
        .accessibilityLabel("Create exercise")
        .accessibilityHint(isValid ? "Double tap to create this exercise" : "Enter a name to create exercise")
    }

    // MARK: - Form Group

    private func formGroup(
        title: String,
        required: Bool = false,
        subtitle: String? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                if required {
                    Text("*")
                        .font(.headline)
                        .foregroundStyle(Color.gymError)
                }
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            content()
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Muscle Option

    private func muscleOption(_ muscle: MuscleGroup, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: AppSpacing.component) {
                Image(systemName: muscle.iconName)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymTextMuted)
                    .frame(width: 24)

                Text(muscle.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(Color.gymText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.gymPrimary)
                        .font(.title3)
                }
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(isSelected ? Color.gymPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(muscle.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Equipment Option

    private func equipmentOption(_ equip: Equipment, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: AppSpacing.component) {
                Image(systemName: equip.iconName)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymTextMuted)
                    .frame(width: 24)

                Text(equip.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(Color.gymText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.gymPrimary)
                        .font(.title3)
                }
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(isSelected ? Color.gymPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(equip.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Save Exercise

    private func saveExercise() {
        isSaving = true

        do {
            let exercise = try ExerciseService.shared.createCustomExercise(
                name: name,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: Array(secondaryMuscles),
                equipment: equipment,
                instructions: instructions.isEmpty ? nil : instructions,
                context: modelContext
            )

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onExerciseCreated?(exercise)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    AddExerciseView()
        .modelContainer(for: [Exercise.self], inMemory: true)
}
