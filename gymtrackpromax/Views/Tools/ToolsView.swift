//
//  ToolsView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct ToolsView: View {
    // MARK: - Tool Definition

    enum Tool: String, CaseIterable, Identifiable {
        case countdownTimer
        case stopwatch
        case bmiCalculator
        case oneRepMax
        case plateCalculator
        case unitConverter

        var id: String { rawValue }

        var title: String {
            switch self {
            case .countdownTimer: return "Timer"
            case .stopwatch: return "Stopwatch"
            case .bmiCalculator: return "BMI"
            case .oneRepMax: return "1RM"
            case .plateCalculator: return "Plates"
            case .unitConverter: return "Converter"
            }
        }

        var description: String {
            switch self {
            case .countdownTimer: return "Countdown for exercises"
            case .stopwatch: return "Track time with laps"
            case .bmiCalculator: return "Body mass index"
            case .oneRepMax: return "Estimate max lift"
            case .plateCalculator: return "Barbell plate loader"
            case .unitConverter: return "lbs ↔ kg converter"
            }
        }

        var icon: String {
            switch self {
            case .countdownTimer: return "timer"
            case .stopwatch: return "stopwatch"
            case .bmiCalculator: return "figure.stand"
            case .oneRepMax: return "dumbbell.fill"
            case .plateCalculator: return "circle.grid.2x1.fill"
            case .unitConverter: return "arrow.left.arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .countdownTimer: return .gymPrimary
            case .stopwatch: return .gymAccent
            case .bmiCalculator: return .gymSuccess
            case .oneRepMax: return .gymWarning
            case .plateCalculator: return Color(hex: 0xF97316)
            case .unitConverter: return Color(hex: 0xA855F7)
            }
        }
    }

    // MARK: - Grid Layout

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.standard),
        GridItem(.flexible(), spacing: AppSpacing.standard)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.standard) {
                    ForEach(Tool.allCases) { tool in
                        NavigationLink(value: tool) {
                            ToolCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.standard)
            }
            .background(Color.gymBackground)
            .navigationTitle("Tools")
            .navigationDestination(for: Tool.self) { tool in
                destinationView(for: tool)
            }
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for tool: Tool) -> some View {
        switch tool {
        case .countdownTimer:
            CountdownTimerView()
        case .stopwatch:
            StopwatchView()
        case .bmiCalculator:
            BMICalculatorView()
        case .oneRepMax:
            OneRepMaxView()
        case .plateCalculator:
            PlateCalculatorView()
        case .unitConverter:
            UnitConverterView()
        }
    }
}

// MARK: - Tool Card

private struct ToolCard: View {
    let tool: ToolsView.Tool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Icon
            Image(systemName: tool.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tool.color)
                .frame(width: 52, height: 52)
                .background(tool.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))

            Spacer(minLength: AppSpacing.small)

            // Title
            Text(tool.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            // Description
            Text(tool.description)
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .accessibleCard(label: "\(tool.title). \(tool.description)")
    }
}

// MARK: - Preview

#Preview {
    ToolsView()
}
