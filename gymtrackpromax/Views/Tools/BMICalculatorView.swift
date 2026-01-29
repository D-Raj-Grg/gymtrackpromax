//
//  BMICalculatorView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct BMICalculatorView: View {
    // MARK: - State

    @State private var useMetric: Bool = true
    @State private var heightCm: Double = 170
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var weightKg: Double = 70
    @State private var weightLbs: Double = 154

    // MARK: - Computed Properties

    private var bmi: Double? {
        let heightM: Double
        let weightKgValue: Double

        if useMetric {
            // Metric: weight in kg, height in ft/in
            let totalInches = Double(heightFeet * 12 + heightInches)
            heightM = totalInches * 0.0254
            weightKgValue = weightKg
        } else {
            // Imperial: weight in lbs, height in cm
            heightM = heightCm / 100
            weightKgValue = weightLbs * 0.453592
        }

        guard heightM > 0 else { return nil }
        return weightKgValue / (heightM * heightM)
    }

    private var bmiCategory: BMICategory? {
        guard let bmi else { return nil }
        return BMICategory.category(for: bmi)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Unit toggle
                unitToggle

                // Height input
                heightInput

                // Weight input
                weightInput

                // Result card
                if let bmi, let category = bmiCategory {
                    resultCard(bmi: bmi, category: category)
                }

                // BMI Chart reference
                bmiReference

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(AppSpacing.standard)
        }
        .background(Color.gymBackground)
        .navigationTitle("BMI Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useMetric = true
                }
                HapticManager.buttonTap()
            } label: {
                Text("Metric")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(useMetric ? Color.gymText : Color.gymTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.component)
                    .background(useMetric ? Color.gymPrimary : Color.clear)
            }

            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useMetric = false
                }
                HapticManager.buttonTap()
            } label: {
                Text("Imperial")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(!useMetric ? Color.gymText : Color.gymTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.component)
                    .background(!useMetric ? Color.gymPrimary : Color.clear)
            }
        }
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
    }

    // MARK: - Height Input

    private var heightInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Height")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            if useMetric {
                // Metric mode: height in ft/in
                HStack(spacing: AppSpacing.standard) {
                    // Feet stepper
                    VStack(spacing: AppSpacing.xs) {
                        Text("Feet")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        HStack(spacing: AppSpacing.small) {
                            Button {
                                if heightFeet > 3 { heightFeet -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.headline)
                                    .foregroundStyle(Color.gymText)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gymCardHover)
                                    .clipShape(Circle())
                            }

                            Text("\(heightFeet)")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.gymText)
                                .frame(minWidth: 40)

                            Button {
                                if heightFeet < 8 { heightFeet += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundStyle(Color.gymText)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gymCardHover)
                                    .clipShape(Circle())
                            }
                        }
                    }

                    // Inches stepper
                    VStack(spacing: AppSpacing.xs) {
                        Text("Inches")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        HStack(spacing: AppSpacing.small) {
                            Button {
                                if heightInches > 0 { heightInches -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.headline)
                                    .foregroundStyle(Color.gymText)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gymCardHover)
                                    .clipShape(Circle())
                            }

                            Text("\(heightInches)")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.gymText)
                                .frame(minWidth: 40)

                            Button {
                                if heightInches < 11 { heightInches += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundStyle(Color.gymText)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gymCardHover)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                // Imperial mode: height in cm
                VStack(spacing: AppSpacing.small) {
                    HStack {
                        Text("\(Int(heightCm))")
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymText)
                        Text("cm")
                            .font(.title3)
                            .foregroundStyle(Color.gymTextMuted)
                    }

                    Slider(value: $heightCm, in: 100...250, step: 1)
                        .tint(Color.gymPrimary)
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Weight Input

    private var weightInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Weight")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            VStack(spacing: AppSpacing.small) {
                HStack {
                    Text(useMetric ? "\(Int(weightKg))" : "\(Int(weightLbs))")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymText)
                    Text(useMetric ? "kg" : "lbs")
                        .font(.title3)
                        .foregroundStyle(Color.gymTextMuted)
                }

                if useMetric {
                    Slider(value: $weightKg, in: 30...200, step: 0.5)
                        .tint(Color.gymPrimary)
                } else {
                    Slider(value: $weightLbs, in: 66...440, step: 1)
                        .tint(Color.gymPrimary)
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Result Card

    private func resultCard(bmi: Double, category: BMICategory) -> some View {
        VStack(spacing: AppSpacing.standard) {
            Text("Your BMI")
                .font(.headline)
                .foregroundStyle(Color.gymTextMuted)

            Text(String(format: "%.1f", bmi))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(category.color)

            Text(category.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(category.color)

            Text(category.description)
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.card)
        .background(category.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(category.color.opacity(0.3), lineWidth: 1)
        )
        .accessibleCard(label: "BMI: \(String(format: "%.1f", bmi)), \(category.name)")
    }

    // MARK: - BMI Reference

    private var bmiReference: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("BMI Categories")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            VStack(spacing: AppSpacing.small) {
                ForEach(BMICategory.allCases, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 12, height: 12)

                        Text(category.name)
                            .font(.subheadline)
                            .foregroundStyle(Color.gymText)

                        Spacer()

                        Text(category.range)
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }
}

// MARK: - BMI Category

private enum BMICategory: CaseIterable {
    case underweight
    case normal
    case overweight
    case obese

    var name: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal: return "Normal"
        case .overweight: return "Overweight"
        case .obese: return "Obese"
        }
    }

    var range: String {
        switch self {
        case .underweight: return "< 18.5"
        case .normal: return "18.5 - 24.9"
        case .overweight: return "25 - 29.9"
        case .obese: return "≥ 30"
        }
    }

    var description: String {
        switch self {
        case .underweight: return "Consider consulting a healthcare provider about healthy weight gain."
        case .normal: return "Great job maintaining a healthy weight!"
        case .overweight: return "Consider focusing on nutrition and exercise habits."
        case .obese: return "Consider consulting a healthcare provider for guidance."
        }
    }

    var color: Color {
        switch self {
        case .underweight: return .gymAccent
        case .normal: return .gymSuccess
        case .overweight: return .gymWarning
        case .obese: return .gymError
        }
    }

    static func category(for bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BMICalculatorView()
    }
}
