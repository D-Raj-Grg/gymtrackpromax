//
//  VolumeChartView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import Charts

struct VolumeChartView: View {
    // MARK: - Properties

    let data: [VolumeDataPoint]
    let weightUnit: WeightUnit

    // MARK: - State

    @State private var selectedDataPoint: VolumeDataPoint?

    // MARK: - Computed Properties

    private var maxVolume: Double {
        data.map { $0.volume }.max() ?? 0
    }

    private var minVolume: Double {
        data.map { $0.volume }.min() ?? 0
    }

    private var averageVolume: Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.volume } / Double(data.count)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Selected point info or average
            if let selected = selectedDataPoint {
                selectedPointInfo(selected)
            } else {
                averageInfo
            }

            // Chart
            chartContent
        }
    }

    // MARK: - Selected Point Info

    private func selectedPointInfo(_ dataPoint: VolumeDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(dataPoint.date))
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text(formatVolume(dataPoint.volume))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
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
            .accessibilityLabel("Dismiss selection")
        }
    }

    private var averageInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Average")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            Text(formatVolume(averageVolume))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
        }
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart {
            // Area fill under the line
            ForEach(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.gymPrimary.opacity(0.4),
                            Color.gymPrimary.opacity(0.1),
                            Color.gymPrimary.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Main line
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(Color.gymPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            // Point markers
            ForEach(data) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(Color.gymPrimary)
                .symbolSize(selectedDataPoint?.id == point.id ? 100 : 30)
            }

            // Selected point indicator
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
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gymBorder.opacity(0.5))
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(shortVolumeFormat(volume))
                            .font(.caption2)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(maxVolume * 1.1))
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
                            .onEnded { _ in
                                // Keep selection visible until dismissed
                            }
                    )
                    .onTapGesture { location in
                        handleChartInteraction(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Volume trend chart with \(data.count) data points. Average volume \(formatVolume(averageVolume))")
        .accessibilityHint("Tap or drag to explore individual data points")
    }

    // MARK: - Interaction

    private func handleChartInteraction(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x

        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find closest data point
        let closest = data.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }

        if let closest = closest {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.easeOut(duration: AppAnimation.quick)) {
                selectedDataPoint = closest
            }
        }
    }

    // MARK: - Formatting

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func shortDateFormat(_ date: Date) -> String {
        date.formatted(.dateTime.month(.twoDigits).day())
    }

    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: volume)) ?? "0") \(weightUnit.symbol)"
    }

    private func shortVolumeFormat(_ volume: Double) -> String {
        if volume >= 1000 {
            return "\(Int(volume / 1000))k"
        }
        return "\(Int(volume))"
    }
}

// MARK: - Preview

#Preview {
    let sampleData = [
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, volume: 12500),
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, volume: 15200),
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, volume: 0),
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, volume: 18900),
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, volume: 14300),
        VolumeDataPoint(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, volume: 16800),
        VolumeDataPoint(date: Date(), volume: 20100)
    ]

    return VStack {
        VolumeChartView(data: sampleData, weightUnit: .kg)
            .frame(height: 200)
            .padding()
    }
    .background(Color.gymCard)
    .previewLayout(.sizeThatFits)
}
