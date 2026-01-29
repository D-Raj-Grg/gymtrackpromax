//
//  PlateCalculatorView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct PlateCalculatorView: View {
    // MARK: - State

    @State private var targetWeight: Double = 135
    @State private var barWeight: Double = 45
    @State private var useKg: Bool = false

    // MARK: - Plate Configuration

    private var availablePlates: [Double] {
        if useKg {
            return [25, 20, 15, 10, 5, 2.5, 1.25]
        } else {
            return [45, 35, 25, 10, 5, 2.5]
        }
    }

    private var barOptions: [Double] {
        if useKg {
            return [20, 15, 10]
        } else {
            return [45, 35, 15]
        }
    }

    // MARK: - Plate Calculation

    private var platesPerSide: [Double] {
        let weightPerSide = (targetWeight - barWeight) / 2
        guard weightPerSide > 0 else { return [] }

        var remaining = weightPerSide
        var plates: [Double] = []

        for plate in availablePlates {
            while remaining >= plate {
                plates.append(plate)
                remaining -= plate
            }
        }

        return plates
    }

    private var actualWeight: Double {
        let platesWeight = platesPerSide.reduce(0, +) * 2
        return barWeight + platesWeight
    }

    private var weightDifference: Double {
        targetWeight - actualWeight
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Unit toggle
                unitToggle

                // Target weight input
                targetWeightInput

                // Bar weight selector
                barWeightSelector

                // Visual plate display
                plateVisual

                // Plates list per side
                platesListCard

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(AppSpacing.standard)
        }
        .background(Color.gymBackground)
        .navigationTitle("Plate Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useKg = false
                    targetWeight = 135
                    barWeight = 45
                }
                HapticManager.buttonTap()
            } label: {
                Text("lbs")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(!useKg ? Color.gymText : Color.gymTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.component)
                    .background(!useKg ? Color.gymPrimary : Color.clear)
            }

            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useKg = true
                    targetWeight = 60
                    barWeight = 20
                }
                HapticManager.buttonTap()
            } label: {
                Text("kg")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(useKg ? Color.gymText : Color.gymTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.component)
                    .background(useKg ? Color.gymPrimary : Color.clear)
            }
        }
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
    }

    // MARK: - Target Weight Input

    private var targetWeightInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Target Weight")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            HStack(spacing: AppSpacing.standard) {
                Button {
                    let increment = useKg ? 2.5 : 5.0
                    if targetWeight > barWeight + increment {
                        targetWeight -= increment
                    }
                    HapticManager.lightImpact()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 48, height: 48)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }

                VStack(spacing: 0) {
                    Text(formattedWeight(targetWeight))
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.gymText)

                    Text(useKg ? "kg" : "lbs")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                }
                .frame(minWidth: 120)

                Button {
                    let increment = useKg ? 2.5 : 5.0
                    targetWeight += increment
                    HapticManager.lightImpact()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 48, height: 48)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    private func formattedWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    // MARK: - Bar Weight Selector

    private var barWeightSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Bar Weight")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            HStack(spacing: AppSpacing.component) {
                ForEach(barOptions, id: \.self) { option in
                    Button {
                        barWeight = option
                        HapticManager.buttonTap()
                    } label: {
                        Text(formattedWeight(option))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(barWeight == option ? Color.gymText : Color.gymTextMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.component)
                            .background(barWeight == option ? Color.gymPrimary : Color.gymCardHover)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
                    }
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Visual Plate Display

    private var plateVisual: some View {
        VStack(spacing: AppSpacing.standard) {
            // Barbell visual
            GeometryReader { geometry in
                let barHeight: CGFloat = 12
                let centerY = geometry.size.height / 2

                ZStack {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gymTextMuted.opacity(0.5))
                        .frame(height: barHeight)
                        .position(x: geometry.size.width / 2, y: centerY)

                    // Left plates
                    HStack(spacing: 2) {
                        ForEach(Array(platesPerSide.enumerated()), id: \.offset) { _, plate in
                            PlateView(weight: plate, useKg: useKg)
                        }
                    }
                    .position(x: geometry.size.width * 0.25, y: centerY)

                    // Right plates (mirrored)
                    HStack(spacing: 2) {
                        ForEach(Array(platesPerSide.reversed().enumerated()), id: \.offset) { _, plate in
                            PlateView(weight: plate, useKg: useKg)
                        }
                    }
                    .position(x: geometry.size.width * 0.75, y: centerY)

                    // Center collar indicator
                    Circle()
                        .fill(Color.gymTextMuted)
                        .frame(width: 20, height: 20)
                        .position(x: geometry.size.width / 2, y: centerY)
                }
            }
            .frame(height: 100)

            // Weight summary
            if weightDifference != 0 {
                Text("Closest: \(formattedWeight(actualWeight)) \(useKg ? "kg" : "lbs")")
                    .font(.caption)
                    .foregroundStyle(Color.gymWarning)
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Plates List Card

    private var platesListCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Plates Per Side")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            if platesPerSide.isEmpty {
                Text("Just the bar!")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.standard)
            } else {
                // Group plates by weight
                let groupedPlates = Dictionary(grouping: platesPerSide, by: { $0 })
                    .sorted { $0.key > $1.key }

                VStack(spacing: AppSpacing.small) {
                    ForEach(groupedPlates, id: \.key) { weight, plates in
                        HStack {
                            Text("\(plates.count)x")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.gymTextMuted)
                                .frame(width: 40, alignment: .leading)

                            Circle()
                                .fill(plateColor(for: weight))
                                .frame(width: 16, height: 16)

                            Text(formattedWeight(weight))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.gymText)

                            Text(useKg ? "kg" : "lbs")
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)

                            Spacer()
                        }
                    }
                }

                Divider()
                    .background(Color.gymBorder)
                    .padding(.vertical, AppSpacing.small)

                // Total
                HStack {
                    Text("Total per side:")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)

                    Spacer()

                    Text("\(formattedWeight(platesPerSide.reduce(0, +))) \(useKg ? "kg" : "lbs")")
                        .font(.headline)
                        .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    private func plateColor(for weight: Double) -> Color {
        if useKg {
            switch weight {
            case 25: return .gymError
            case 20: return .gymPrimary
            case 15: return Color(hex: 0xFCD34D)
            case 10: return .gymSuccess
            case 5: return Color.white
            case 2.5: return .gymError
            default: return .gymTextMuted
            }
        } else {
            switch weight {
            case 45: return .gymPrimary
            case 35: return Color(hex: 0xFCD34D)
            case 25: return .gymSuccess
            case 10: return Color.white
            case 5: return .gymError
            case 2.5: return .gymTextMuted
            default: return .gymTextMuted
            }
        }
    }
}

// MARK: - Plate View

private struct PlateView: View {
    let weight: Double
    let useKg: Bool

    private var plateHeight: CGFloat {
        if useKg {
            switch weight {
            case 25: return 70
            case 20: return 65
            case 15: return 55
            case 10: return 45
            case 5: return 35
            case 2.5: return 28
            default: return 22
            }
        } else {
            switch weight {
            case 45: return 70
            case 35: return 60
            case 25: return 50
            case 10: return 40
            case 5: return 32
            case 2.5: return 26
            default: return 22
            }
        }
    }

    private var plateColor: Color {
        if useKg {
            switch weight {
            case 25: return .gymError
            case 20: return .gymPrimary
            case 15: return Color(hex: 0xFCD34D)
            case 10: return .gymSuccess
            case 5: return Color.white
            case 2.5: return .gymError
            default: return .gymTextMuted
            }
        } else {
            switch weight {
            case 45: return .gymPrimary
            case 35: return Color(hex: 0xFCD34D)
            case 25: return .gymSuccess
            case 10: return Color.white
            case 5: return .gymError
            case 2.5: return .gymTextMuted
            default: return .gymTextMuted
            }
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(plateColor)
            .frame(width: 8, height: plateHeight)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlateCalculatorView()
    }
}
