//
//  ExerciseChartView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import Charts

struct ExerciseChartView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let exerciseProgress: ExerciseProgress
    let sessions: [WorkoutSession]
    let weightUnit: WeightUnit

    // MARK: - State

    @State private var selectedDataPoint: ChartDataPoint?
    @State private var chartData: [ChartDataPoint] = []
    @State private var prPoints: [ChartDataPoint] = []

    // MARK: - Data Structure

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let reps: Int
        let estimated1RM: Double
        let isPR: Bool
    }

    // MARK: - Computed Properties

    private var best1RM: Double {
        chartData.map { $0.estimated1RM }.max() ?? 0
    }

    private var bestWeight: Double {
        chartData.map { $0.weight }.max() ?? 0
    }

    private var totalSets: Int {
        chartData.count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Header with back button
                    headerSection

                    // Stats cards
                    statsSection
                        .padding(.horizontal, AppSpacing.standard)

                    // Main chart
                    chartSection
                        .padding(.horizontal, AppSpacing.standard)

                    // Recent history
                    recentHistorySection
                        .padding(.horizontal, AppSpacing.standard)

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.top, AppSpacing.standard)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadChartData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(exerciseProgress.exercise.name)
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: exerciseProgress.exercise.primaryMuscle.iconName)
                        .font(.caption2)
                    Text(exerciseProgress.exercise.primaryMuscle.displayName)
                        .font(.caption)
                }
                .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "chevron.left")
                .font(.title3)
                .opacity(0)
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: AppSpacing.component) {
            StatBox(
                title: "Best 1RM",
                value: formatWeight(best1RM),
                unit: weightUnit.symbol,
                icon: "trophy.fill",
                color: Color.gymSuccess
            )

            StatBox(
                title: "Best Weight",
                value: formatWeight(bestWeight),
                unit: weightUnit.symbol,
                icon: "scalemass.fill",
                color: Color.gymPrimary
            )

            StatBox(
                title: "Total Sets",
                value: "\(totalSets)",
                unit: nil,
                icon: "number",
                color: Color.gymAccent
            )
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("Weight Progression")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                // Legend
                HStack(spacing: AppSpacing.component) {
                    legendItem(color: Color.gymPrimary, label: "Weight")
                    legendItem(color: Color.gymSuccess, label: "PR")
                }
            }

            // Selected point info
            if let selected = selectedDataPoint {
                selectedPointInfo(selected)
            }

            // Chart
            Chart {
                // Main line
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(Color.gymPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Area fill
                ForEach(chartData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.gymPrimary.opacity(0.3),
                                Color.gymPrimary.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Points
                ForEach(chartData) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(point.isPR ? Color.gymSuccess : Color.gymPrimary)
                    .symbolSize(point.isPR ? 100 : (selectedDataPoint?.id == point.id ? 80 : 40))
                }

                // PR markers
                ForEach(prPoints) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(Color.gymSuccess)
                    .symbolSize(120)
                    .symbol {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.gymSuccess)
                            .font(.caption2)
                    }
                }

                // Selected point rule
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.gymAccent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gymBorder.opacity(0.5))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(shortDateFormat(date))
                                .font(.caption2)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gymBorder.opacity(0.5))
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight))")
                                .font(.caption2)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }
                }
            }
            .frame(height: 250)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleChartInteraction(at: value.location, proxy: proxy, geometry: geometry)
                                }
                        )
                        .onTapGesture { location in
                            handleChartInteraction(at: location, proxy: proxy, geometry: geometry)
                        }
                }
            }
        }
        .padding(AppSpacing.card)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    private func selectedPointInfo(_ point: ChartDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatFullDate(point.date))
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                HStack(spacing: AppSpacing.small) {
                    Text("\(formatWeight(point.weight)) x \(point.reps)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymText)

                    if point.isPR {
                        Text("PR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gymSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.gymSuccess.opacity(0.2))
                            )
                    }
                }

                Text("Est. 1RM: \(formatWeight(point.estimated1RM)) \(weightUnit.symbol)")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: AppAnimation.quick)) {
                    selectedDataPoint = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(Color.gymCardHover)
        )
    }

    // MARK: - Recent History Section

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Recent History")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            VStack(spacing: AppSpacing.small) {
                ForEach(Array(chartData.sorted { $0.date > $1.date }.prefix(10))) { point in
                    historyRow(point)
                }
            }
        }
        .padding(AppSpacing.card)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    private func historyRow(_ point: ChartDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatFullDate(point.date))
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                HStack(spacing: AppSpacing.small) {
                    Text("\(formatWeight(point.weight)) x \(point.reps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)

                    if point.isPR {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.gymSuccess)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Est. 1RM")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)

                Text("\(formatWeight(point.estimated1RM)) \(weightUnit.symbol)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
            }
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(Color.gymCardHover.opacity(0.5))
        )
    }

    // MARK: - Interaction

    private func handleChartInteraction(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x

        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find closest data point
        let closest = chartData.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }

        if let closest = closest {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.easeOut(duration: AppAnimation.quick)) {
                selectedDataPoint = closest
            }
        }
    }

    // MARK: - Data Loading

    private func loadChartData() {
        var dataPoints: [ChartDataPoint] = []
        var currentBest1RM: Double = 0

        // Sort sessions chronologically
        let sortedSessions = sessions.filter { $0.isCompleted }.sorted { $0.startTime < $1.startTime }

        for session in sortedSessions {
            for log in session.exerciseLogs {
                guard log.exercise?.id == exerciseProgress.exercise.id else { continue }

                for set in log.workingSetsArray {
                    let isPR = set.estimated1RM > currentBest1RM
                    if isPR {
                        currentBest1RM = set.estimated1RM
                    }

                    dataPoints.append(ChartDataPoint(
                        date: session.startTime,
                        weight: set.weight,
                        reps: set.reps,
                        estimated1RM: set.estimated1RM,
                        isPR: isPR
                    ))
                }
            }
        }

        chartData = dataPoints
        prPoints = dataPoints.filter { $0.isPR }
    }

    // MARK: - Formatting

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    private func shortDateFormat(_ date: Date) -> String {
        date.formatted(.dateTime.month(.twoDigits).day())
    }

    private func formatFullDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        name: "Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )

    let progress = ExerciseProgress(
        exercise: exercise,
        estimated1RM: 100,
        bestWeight: 90,
        bestReps: 5,
        totalSets: 45,
        recentDataPoints: []
    )

    return ExerciseChartView(
        exerciseProgress: progress,
        sessions: [],
        weightUnit: .kg
    )
}
