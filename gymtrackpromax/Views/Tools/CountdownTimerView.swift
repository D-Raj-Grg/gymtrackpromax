//
//  CountdownTimerView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct CountdownTimerView: View {
    // MARK: - State

    @State private var timerService = TimerService()
    @State private var selectedDuration: TimeInterval = 60
    @State private var showCustomPicker = false
    @State private var customMinutes: Int = 1
    @State private var customSeconds: Int = 0

    // MARK: - Preset Durations

    private let presets: [(label: String, duration: TimeInterval)] = [
        ("30s", 30),
        ("60s", 60),
        ("90s", 90),
        ("2min", 120),
        ("3min", 180),
        ("5min", 300)
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            // Timer display
            timerDisplay

            Spacer()

            // Preset buttons
            presetButtons

            // Custom duration button
            customDurationButton

            // Control buttons
            controlButtons

            Spacer()
        }
        .padding(AppSpacing.standard)
        .background(Color.gymBackground)
        .navigationTitle("Countdown Timer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomPicker) {
            customDurationPicker
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gymCardHover, lineWidth: 12)
                .frame(width: 250, height: 250)

            // Progress circle
            Circle()
                .trim(from: 0, to: timerService.isRunning || timerService.isPaused ? CGFloat(1 - timerService.progress) : 1)
                .stroke(
                    Color.gymPrimary,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerService.progress)

            // Time text
            VStack(spacing: AppSpacing.xs) {
                Text(displayTime)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.gymText)

                if timerService.isRunning || timerService.isPaused {
                    Text(timerService.isPaused ? "Paused" : "Running")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timer: \(displayTime)")
        .accessibilityValue(timerService.isRunning ? "Running" : timerService.isPaused ? "Paused" : "Stopped")
    }

    private var displayTime: String {
        let time = timerService.isRunning || timerService.isPaused ? timerService.remainingTime : selectedDuration
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Preset Buttons

    private var presetButtons: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.component) {
            ForEach(presets, id: \.duration) { preset in
                Button {
                    HapticManager.buttonTap()
                    selectedDuration = preset.duration
                    if !timerService.isRunning && !timerService.isPaused {
                        // Only update if timer is not active
                    }
                } label: {
                    Text(preset.label)
                        .font(.headline)
                        .foregroundStyle(selectedDuration == preset.duration && !timerService.isRunning ? Color.gymPrimary : Color.gymText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.component)
                        .background(
                            selectedDuration == preset.duration && !timerService.isRunning
                                ? Color.gymPrimary.opacity(0.2)
                                : Color.gymCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
                }
                .disabled(timerService.isRunning || timerService.isPaused)
                .opacity(timerService.isRunning || timerService.isPaused ? 0.5 : 1)
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Custom Duration Button

    private var customDurationButton: some View {
        Button {
            HapticManager.buttonTap()
            showCustomPicker = true
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Custom Duration")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.gymPrimary)
        }
        .disabled(timerService.isRunning || timerService.isPaused)
        .opacity(timerService.isRunning || timerService.isPaused ? 0.5 : 1)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: AppSpacing.section) {
            // Reset button
            Button {
                HapticManager.buttonTap()
                timerService.stop()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(Color.gymText)
                    .frame(width: 60, height: 60)
                    .background(Color.gymCard)
                    .clipShape(Circle())
            }
            .opacity(timerService.isRunning || timerService.isPaused ? 1 : 0.5)
            .disabled(!timerService.isRunning && !timerService.isPaused)
            .accessibleButton(label: "Reset timer")

            // Start/Pause button
            Button {
                HapticManager.buttonTap()
                if timerService.isRunning {
                    timerService.pause()
                } else if timerService.isPaused {
                    timerService.resume()
                } else {
                    timerService.start(duration: selectedDuration)
                }
            } label: {
                Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(Color.white)
                    .frame(width: 80, height: 80)
                    .background(Color.gymPrimary)
                    .clipShape(Circle())
            }
            .accessibleButton(label: timerService.isRunning ? "Pause timer" : "Start timer")

            // Skip button (only when running)
            Button {
                HapticManager.buttonTap()
                timerService.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(Color.gymText)
                    .frame(width: 60, height: 60)
                    .background(Color.gymCard)
                    .clipShape(Circle())
            }
            .opacity(timerService.isRunning ? 1 : 0.5)
            .disabled(!timerService.isRunning)
            .accessibleButton(label: "Skip timer")
        }
    }

    // MARK: - Custom Duration Picker

    private var customDurationPicker: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.section) {
                Text("Set Custom Duration")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
                    .padding(.top, AppSpacing.section)

                HStack(spacing: AppSpacing.section) {
                    // Minutes picker
                    VStack(spacing: AppSpacing.small) {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        Picker("Minutes", selection: $customMinutes) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                        .clipped()
                    }

                    Text(":")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymText)

                    // Seconds picker
                    VStack(spacing: AppSpacing.small) {
                        Text("Seconds")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        Picker("Seconds", selection: $customSeconds) {
                            ForEach(0..<60, id: \.self) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 150)
                        .clipped()
                    }
                }

                Spacer()

                Button {
                    let duration = TimeInterval(customMinutes * 60 + customSeconds)
                    if duration > 0 {
                        selectedDuration = duration
                    }
                    showCustomPicker = false
                } label: {
                    Text("Set Duration")
                }
                .primaryButtonStyle()
                .padding(.horizontal, AppSpacing.standard)
                .padding(.bottom, AppSpacing.section)
            }
            .background(Color.gymBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showCustomPicker = false
                    }
                    .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CountdownTimerView()
    }
}
