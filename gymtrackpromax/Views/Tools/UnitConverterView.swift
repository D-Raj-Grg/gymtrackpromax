//
//  UnitConverterView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct UnitConverterView: View {
    // MARK: - State

    @State private var inputValue: String = ""
    @State private var fromUnit: WeightUnit = .lbs
    @FocusState private var isInputFocused: Bool

    // MARK: - Computed Properties

    private var inputNumber: Double? {
        Double(inputValue)
    }

    private var convertedValue: Double? {
        guard let input = inputNumber else { return nil }
        let toUnit: WeightUnit = fromUnit == .lbs ? .kg : .lbs
        return fromUnit.convert(input, to: toUnit)
    }

    private var toUnit: WeightUnit {
        fromUnit == .lbs ? .kg : .lbs
    }

    // MARK: - Common Presets (in lbs)

    private let presets: [Double] = [135, 185, 225, 275, 315, 365, 405, 495]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Input section
                inputSection

                // Swap button
                swapButton

                // Result section
                resultSection

                // Quick presets
                presetsSection

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(AppSpacing.standard)
        }
        .background(Color.gymBackground)
        .navigationTitle("Unit Converter")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isInputFocused = false
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("From")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppSpacing.component) {
                TextField("0", text: $inputValue)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.gymText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isInputFocused)

                Text(fromUnit.symbol)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymPrimary)
                    .frame(width: 50)
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(isInputFocused ? Color.gymPrimary : Color.gymBorder, lineWidth: isInputFocused ? 2 : 1)
        )
    }

    // MARK: - Swap Button

    private var swapButton: some View {
        Button {
            HapticManager.buttonTap()
            withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                // Swap units
                let temp = fromUnit
                fromUnit = toUnit
                // Also swap the value if there's a valid conversion
                if let converted = convertedValue {
                    inputValue = String(format: "%.1f", converted)
                }
                // Reset to new fromUnit
                fromUnit = temp == .lbs ? .kg : .lbs
            }
        } label: {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                Text("Swap")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.gymPrimary)
            .padding(.horizontal, AppSpacing.card)
            .padding(.vertical, AppSpacing.component)
            .background(Color.gymPrimary.opacity(0.15))
            .clipShape(Capsule())
        }
        .accessibleButton(label: "Swap units")
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("To")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppSpacing.component) {
                Text(formattedResult)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(convertedValue != nil ? Color.gymSuccess : Color.gymTextMuted)

                Text(toUnit.symbol)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymSuccess.opacity(0.8))
                    .frame(width: 50)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.card)
        .background(Color.gymSuccess.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(Color.gymSuccess.opacity(0.3), lineWidth: 1)
        )
        .accessibleCard(label: convertedValue != nil ? "\(formattedResult) \(toUnit.symbol)" : "Enter a value to convert")
    }

    private var formattedResult: String {
        guard let value = convertedValue else { return "—" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Quick Conversions")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.component) {
                ForEach(presets, id: \.self) { preset in
                    let convertedPreset = WeightUnit.lbs.convert(preset, to: .kg)

                    Button {
                        HapticManager.buttonTap()
                        fromUnit = .lbs
                        inputValue = String(format: "%.0f", preset)
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            Text("\(Int(preset))")
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.gymText)

                            HStack(spacing: AppSpacing.xs) {
                                Text("lbs")
                                    .font(.caption)
                                    .foregroundStyle(Color.gymTextMuted)

                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(Color.gymTextMuted)

                                Text(String(format: "%.1f", convertedPreset))
                                    .font(.caption)
                                    .foregroundStyle(Color.gymAccent)

                                Text("kg")
                                    .font(.caption)
                                    .foregroundStyle(Color.gymTextMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.component)
                        .background(Color.gymCardHover)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
                    }
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
        UnitConverterView()
    }
}
