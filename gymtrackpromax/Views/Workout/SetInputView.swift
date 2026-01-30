//
//  SetInputView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct SetInputView: View {
    // MARK: - Properties

    @Binding var weight: Double
    @Binding var reps: Int
    @Binding var duration: Int
    @Binding var rpe: Int?
    @Binding var isWarmup: Bool
    @Binding var isDropset: Bool

    let exerciseType: ExerciseType
    let weightUnit: WeightUnit
    let canDuplicateLastSet: Bool
    let onLogSet: () -> Void
    let onDuplicateLastSet: () -> Void
    let onIncrementWeight: () -> Void
    let onDecrementWeight: () -> Void
    let onIncrementReps: () -> Void
    let onDecrementReps: () -> Void

    // MARK: - State

    @State private var showRPEPicker = false
    @State private var showWeightForBodyweight = false
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var isEditingWeight = false
    @State private var weightText = ""
    @State private var isEditingReps = false
    @State private var repsText = ""
    @FocusState private var weightFieldFocused: Bool
    @FocusState private var repsFieldFocused: Bool

    // MARK: - Constants

    private let durationIncrement = 5 // seconds

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.standard) {
            // Input controls based on exercise type
            inputSection

            // Options row (warmup, dropset, RPE) - hide RPE for duration-only exercises
            optionsRow

            // Log Set and Copy Last buttons
            HStack(spacing: AppSpacing.component) {
                // Copy Last button
                Button(action: {
                    onDuplicateLastSet()
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Last")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(canDuplicateLastSet ? Color.gymPrimary : Color.gymTextMuted)
                    .padding(.horizontal, AppSpacing.component)
                    .padding(.vertical, AppSpacing.component)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.button)
                            .fill(canDuplicateLastSet ? Color.gymPrimary.opacity(0.15) : Color.gymCardHover)
                    )
                }
                .disabled(!canDuplicateLastSet)
                .accessibilityLabel("Copy last set")
                .accessibilityHint(canDuplicateLastSet ? "Double tap to copy from last set" : "No previous sets to copy")

                // Log Set button
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    }
                    HapticManager.setLogged()
                    onLogSet()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Log Set")
                    }
                }
                .primaryButtonStyle()
                .accessibleButton(label: "Log Set", hint: "Double tap to save this set")
            }
        }
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        switch exerciseType {
        case .weightAndReps:
            // Standard: Weight + Reps
            HStack(spacing: AppSpacing.standard) {
                weightStepper
                repsStepper
            }

        case .repsOnly:
            // Bodyweight: Reps + optional weight toggle
            VStack(spacing: AppSpacing.component) {
                HStack(spacing: AppSpacing.standard) {
                    if showWeightForBodyweight {
                        weightStepper
                    }
                    repsStepper
                }

                if !showWeightForBodyweight {
                    addWeightButton
                } else {
                    removeWeightButton
                }
            }

        case .duration:
            // Timed: Duration only
            durationSection

        case .weightAndDuration:
            // Weighted timed: Weight + Duration
            HStack(spacing: AppSpacing.standard) {
                weightStepper
                durationStepper
            }
        }
    }

    // MARK: - Options Row

    private var optionsRow: some View {
        HStack(spacing: AppSpacing.component) {
            // Warmup toggle
            warmupToggle

            // Dropset toggle (only for rep-based exercises)
            if exerciseType.showsReps {
                dropsetToggle
            }

            Spacer()

            // RPE picker (not for pure duration exercises)
            if exerciseType != .duration {
                rpePicker
            }
        }
    }

    // MARK: - Weight Stepper

    private var weightStepper: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Weight")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            HStack(spacing: AppSpacing.small) {
                Button {
                    onDecrementWeight()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }

                VStack(spacing: 0) {
                    if isEditingWeight {
                        TextField("0", text: $weightText)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymText)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .focused($weightFieldFocused)
                            .frame(minWidth: 60)
                            .onSubmit { commitWeightEdit() }
                            .onChange(of: weightFieldFocused) { _, focused in
                                if !focused { commitWeightEdit() }
                            }
                    } else {
                        Text(formattedWeight)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymText)
                            .frame(minWidth: 60)
                            .onTapGesture {
                                weightText = formattedWeight
                                isEditingWeight = true
                                weightFieldFocused = true
                            }
                    }

                    Text(weightUnit.symbol)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Button {
                    onIncrementWeight()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
            }
        }
    }

    private var formattedWeight: String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    private func commitWeightEdit() {
        if let value = Double(weightText), value >= 0 {
            weight = value
        }
        isEditingWeight = false
    }

    private func commitRepsEdit() {
        if let value = Int(repsText), value >= 0 {
            reps = value
        }
        isEditingReps = false
    }

    // MARK: - Reps Stepper

    private var repsStepper: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Reps")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            HStack(spacing: AppSpacing.small) {
                Button {
                    onDecrementReps()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }

                Group {
                    if isEditingReps {
                        TextField("0", text: $repsText)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymText)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($repsFieldFocused)
                            .frame(minWidth: 40)
                            .onSubmit { commitRepsEdit() }
                            .onChange(of: repsFieldFocused) { _, focused in
                                if !focused { commitRepsEdit() }
                            }
                    } else {
                        Text("\(reps)")
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymText)
                            .frame(minWidth: 40)
                            .onTapGesture {
                                repsText = "\(reps)"
                                isEditingReps = true
                                repsFieldFocused = true
                            }
                    }
                }

                Button {
                    onIncrementReps()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Duration Section (Full width for duration-only)

    private var durationSection: some View {
        VStack(spacing: AppSpacing.component) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            // Large duration display
            Text(formattedDuration)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(isTimerRunning ? Color.gymAccent : Color.gymText)

            // Stepper controls
            HStack(spacing: AppSpacing.large) {
                Button {
                    decrementDuration()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
                .disabled(isTimerRunning)

                Button {
                    incrementDuration()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
                .disabled(isTimerRunning)
            }

            // Timer button
            timerButton
        }
    }

    // MARK: - Duration Stepper (For weight + duration layout)

    private var durationStepper: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            HStack(spacing: AppSpacing.small) {
                Button {
                    decrementDuration()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
                .disabled(isTimerRunning)

                VStack(spacing: 0) {
                    Text(formattedDuration)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(isTimerRunning ? Color.gymAccent : Color.gymText)
                        .frame(minWidth: 60)

                    // Mini timer button
                    Button {
                        toggleTimer()
                    } label: {
                        Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                            .font(.caption)
                            .foregroundStyle(isTimerRunning ? Color.gymAccent : Color.gymTextMuted)
                    }
                }

                Button {
                    incrementDuration()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 44, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
                .disabled(isTimerRunning)
            }
        }
    }

    // MARK: - Timer Button

    private var timerButton: some View {
        Button {
            toggleTimer()
        } label: {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                Text(isTimerRunning ? "Stop Timer" : "Start Timer")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(isTimerRunning ? Color.gymText : Color.gymAccent)
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(isTimerRunning ? Color.gymAccent : Color.gymAccent.opacity(0.15))
            )
        }
    }

    // MARK: - Add/Remove Weight Buttons (for bodyweight)

    private var addWeightButton: some View {
        Button {
            HapticManager.buttonTap()
            showWeightForBodyweight = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle")
                    .font(.caption)
                Text("Add Weight")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.gymTextMuted)
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(Color.gymCardHover)
            )
        }
    }

    private var removeWeightButton: some View {
        Button {
            HapticManager.buttonTap()
            showWeightForBodyweight = false
            weight = 0
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "minus.circle")
                    .font(.caption)
                Text("Remove Weight")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.gymTextMuted)
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(Color.gymCardHover)
            )
        }
    }

    // MARK: - Duration Helpers

    private var formattedDuration: String {
        let mins = duration / 60
        let secs = duration % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func incrementDuration() {
        duration += durationIncrement
        HapticManager.buttonTap()
    }

    private func decrementDuration() {
        duration = max(0, duration - durationIncrement)
        HapticManager.buttonTap()
    }

    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isTimerRunning = true
        timerStartTime = Date()
        duration = 0
        HapticManager.buttonTap()

        // Start a timer to update duration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isTimerRunning, let startTime = timerStartTime {
                duration = Int(Date().timeIntervalSince(startTime))
            } else {
                timer.invalidate()
            }
        }
    }

    private func stopTimer() {
        isTimerRunning = false
        if let startTime = timerStartTime {
            duration = Int(Date().timeIntervalSince(startTime))
        }
        timerStartTime = nil
        HapticManager.setLogged()
    }

    // MARK: - Warmup Toggle

    private var warmupToggle: some View {
        Button {
            isWarmup.toggle()
            if isWarmup {
                isDropset = false
            }
            HapticManager.buttonTap()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isWarmup ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isWarmup ? Color.gymWarning : Color.gymTextMuted)
                Text("Warmup")
                    .font(.subheadline)
                    .foregroundStyle(isWarmup ? Color.gymWarning : Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(isWarmup ? Color.gymWarning.opacity(0.15) : Color.gymCardHover)
            .clipShape(Capsule())
        }
    }

    // MARK: - Dropset Toggle

    private var dropsetToggle: some View {
        Button {
            isDropset.toggle()
            if isDropset {
                isWarmup = false
            }
            HapticManager.buttonTap()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isDropset ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDropset ? Color.gymAccent : Color.gymTextMuted)
                Text("Drop")
                    .font(.subheadline)
                    .foregroundStyle(isDropset ? Color.gymAccent : Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(isDropset ? Color.gymAccent.opacity(0.15) : Color.gymCardHover)
            .clipShape(Capsule())
        }
    }

    // MARK: - RPE Picker

    private var rpePicker: some View {
        Menu {
            Button("None") {
                rpe = nil
            }
            ForEach((6...10), id: \.self) { value in
                Button("RPE \(value)") {
                    rpe = value
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(rpe != nil ? "RPE \(rpe!)" : "RPE")
                    .font(.subheadline)
                    .fontWeight(rpe != nil ? .semibold : .regular)
                    .foregroundStyle(rpe != nil ? Color.gymPrimary : Color.gymTextMuted)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(rpe != nil ? Color.gymPrimary.opacity(0.15) : Color.gymCardHover)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Weight × Reps") {
    @Previewable @State var weight: Double = 80.0
    @Previewable @State var reps: Int = 10
    @Previewable @State var duration: Int = 0
    @Previewable @State var rpe: Int? = 8
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    SetInputView(
        weight: $weight,
        reps: $reps,
        duration: $duration,
        rpe: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        exerciseType: .weightAndReps,
        weightUnit: .kg,
        canDuplicateLastSet: true,
        onLogSet: { print("Log set") },
        onDuplicateLastSet: { print("Copy last set") },
        onIncrementWeight: { weight += 0.5 },
        onDecrementWeight: { weight -= 0.5 },
        onIncrementReps: { reps += 1 },
        onDecrementReps: { reps -= 1 }
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Duration (Plank)") {
    @Previewable @State var weight: Double = 0
    @Previewable @State var reps: Int = 0
    @Previewable @State var duration: Int = 45
    @Previewable @State var rpe: Int? = nil
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    SetInputView(
        weight: $weight,
        reps: $reps,
        duration: $duration,
        rpe: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        exerciseType: .duration,
        weightUnit: .kg,
        canDuplicateLastSet: false,
        onLogSet: { print("Log set: \(duration) seconds") },
        onDuplicateLastSet: {},
        onIncrementWeight: {},
        onDecrementWeight: {},
        onIncrementReps: {},
        onDecrementReps: {}
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Reps Only (Push-up)") {
    @Previewable @State var weight: Double = 0
    @Previewable @State var reps: Int = 15
    @Previewable @State var duration: Int = 0
    @Previewable @State var rpe: Int? = nil
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    SetInputView(
        weight: $weight,
        reps: $reps,
        duration: $duration,
        rpe: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        exerciseType: .repsOnly,
        weightUnit: .kg,
        canDuplicateLastSet: true,
        onLogSet: { print("Log set: \(reps) reps") },
        onDuplicateLastSet: { print("Copy last set") },
        onIncrementWeight: { weight += 0.5 },
        onDecrementWeight: { weight = max(0, weight - 0.5) },
        onIncrementReps: { reps += 1 },
        onDecrementReps: { reps = max(0, reps - 1) }
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Weight × Duration (Farmer's Walk)") {
    @Previewable @State var weight: Double = 30.0
    @Previewable @State var reps: Int = 0
    @Previewable @State var duration: Int = 60
    @Previewable @State var rpe: Int? = nil
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    SetInputView(
        weight: $weight,
        reps: $reps,
        duration: $duration,
        rpe: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        exerciseType: .weightAndDuration,
        weightUnit: .kg,
        canDuplicateLastSet: true,
        onLogSet: { print("Log set: \(weight)kg × \(duration)s") },
        onDuplicateLastSet: { print("Copy last set") },
        onIncrementWeight: { weight += 0.5 },
        onDecrementWeight: { weight = max(0, weight - 0.5) },
        onIncrementReps: {},
        onDecrementReps: {}
    )
    .padding()
    .background(Color.gymBackground)
}
