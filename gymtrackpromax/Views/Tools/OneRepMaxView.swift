//
//  OneRepMaxView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct OneRepMaxView: View {
    // MARK: - State

    @State private var weight: Double = 100
    @State private var reps: Int = 5
    @State private var useKg: Bool = true

    // MARK: - 1RM Calculation (Epley Formula)

    private var oneRepMax: Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    // MARK: - Percentage Table

    private let percentages: [(percent: Int, reps: String)] = [
        (100, "1"),
        (95, "2"),
        (90, "3-4"),
        (85, "5-6"),
        (80, "7-8"),
        (75, "9-10"),
        (70, "11-12"),
        (65, "13-15"),
        (60, "16-20")
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Unit toggle
                unitToggle

                // Weight input
                weightInput

                // Reps input
                repsInput

                // Result card
                resultCard

                // Percentage chart
                percentageChart

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(AppSpacing.standard)
        }
        .background(Color.gymBackground)
        .navigationTitle("1RM Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useKg = true
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

            Button {
                withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                    useKg = false
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
        }
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
    }

    // MARK: - Weight Input

    private var weightInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Weight Lifted")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            HStack(spacing: AppSpacing.standard) {
                Button {
                    if weight > 5 { weight -= 5 }
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
                    Text(formattedWeight)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.gymText)

                    Text(useKg ? "kg" : "lbs")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                }
                .frame(minWidth: 120)

                Button {
                    weight += 5
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

    private var formattedWeight: String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    // MARK: - Reps Input

    private var repsInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Reps Performed")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            HStack(spacing: AppSpacing.standard) {
                Button {
                    if reps > 1 { reps -= 1 }
                    HapticManager.lightImpact()
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 48, height: 48)
                        .background(Color.gymCardHover)
                        .clipShape(Circle())
                }

                Text("\(reps)")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.gymText)
                    .frame(minWidth: 120)

                Button {
                    if reps < 30 { reps += 1 }
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

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(spacing: AppSpacing.component) {
            Text("Estimated 1RM")
                .font(.headline)
                .foregroundStyle(Color.gymTextMuted)

            Text(String(format: "%.1f", oneRepMax))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.gymPrimary)

            Text(useKg ? "kg" : "lbs")
                .font(.title3)
                .foregroundStyle(Color.gymTextMuted)

            Text("Epley Formula")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.card)
        .background(Color.gymPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(Color.gymPrimary.opacity(0.3), lineWidth: 1)
        )
        .accessibleCard(label: "Estimated one rep max: \(String(format: "%.1f", oneRepMax)) \(useKg ? "kilograms" : "pounds")")
    }

    // MARK: - Percentage Chart

    private var percentageChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Training Percentages")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            VStack(spacing: AppSpacing.small) {
                // Header
                HStack {
                    Text("%1RM")
                        .frame(width: 60, alignment: .leading)
                    Text("Weight")
                        .frame(maxWidth: .infinity)
                    Text("Reps")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymTextMuted)

                Divider()
                    .background(Color.gymBorder)

                ForEach(percentages, id: \.percent) { item in
                    HStack {
                        Text("\(item.percent)%")
                            .frame(width: 60, alignment: .leading)
                            .foregroundStyle(Color.gymTextMuted)

                        Text(String(format: "%.1f", oneRepMax * Double(item.percent) / 100))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gymText)
                            .frame(maxWidth: .infinity)

                        Text(item.reps)
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                    .font(.subheadline)
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OneRepMaxView()
    }
}
