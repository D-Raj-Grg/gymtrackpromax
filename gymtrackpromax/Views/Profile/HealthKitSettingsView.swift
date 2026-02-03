//
//  HealthKitSettingsView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import SwiftUI
import SwiftData
import HealthKit

/// Settings view for Apple Health (HealthKit) integration
struct HealthKitSettingsView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endTime != nil },
        sort: \WorkoutSession.startTime,
        order: .reverse
    )
    private var completedSessions: [WorkoutSession]

    @Query private var users: [User]

    // MARK: - State

    @State private var isEnabled: Bool = HealthKitService.shared.isEnabled
    @State private var isAuthorizing: Bool = false
    @State private var isSyncing: Bool = false
    @State private var latestWeight: (weight: Double, date: Date)?
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var syncResult: Int?

    // MARK: - Computed Properties

    private var healthKitService: HealthKitService { HealthKitService.shared }

    private var isHealthKitAvailable: Bool {
        healthKitService.isHealthKitAvailable
    }

    private var authorizationStatusText: String {
        switch healthKitService.workoutAuthorizationStatus {
        case .notDetermined:
            return "Not Set Up"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }

    private var authorizationStatusColor: Color {
        switch healthKitService.workoutAuthorizationStatus {
        case .sharingAuthorized:
            return Color.gymSuccess
        case .sharingDenied:
            return Color.gymError
        default:
            return Color.gymTextMuted
        }
    }

    private var weightUnit: WeightUnit {
        users.first?.weightUnit ?? .kg
    }

    private var formattedWeight: String? {
        guard let weight = latestWeight else { return nil }

        let displayWeight: Double
        switch weightUnit {
        case .kg:
            displayWeight = weight.weight
        case .lbs:
            displayWeight = weight.weight * 2.20462
        }

        return String(format: "%.1f %@", displayWeight, weightUnit.symbol)
    }

    private var formattedWeightDate: String? {
        guard let weight = latestWeight else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: weight.date, relativeTo: Date())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            if !isHealthKitAvailable {
                notAvailableView
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Enable/Disable toggle
                        toggleSection

                        if isEnabled {
                            // Authorization status
                            authorizationSection

                            // Body weight from Health
                            bodyWeightSection

                            // Historical sync
                            historicalSyncSection
                        }

                        // Info section
                        infoSection

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Apple Health")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadBodyWeight()
        }
    }

    // MARK: - Not Available View

    private var notAvailableView: some View {
        VStack(spacing: AppSpacing.section) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(Color.gymTextMuted)

            Text("HealthKit Not Available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Apple Health is not available on this device.")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)
        }
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            settingsCard {
                Toggle(isOn: $isEnabled) {
                    HStack(spacing: AppSpacing.component) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with Apple Health")
                                .font(.body)
                                .foregroundStyle(Color.gymText)

                            Text("Save workouts and read body weight")
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }
                }
                .tint(Color.gymPrimary)
                .onChange(of: isEnabled) { _, newValue in
                    handleToggleChange(newValue)
                }
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Authorization Section

    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Authorization")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                VStack(spacing: AppSpacing.component) {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(authorizationStatusColor)
                            .frame(width: 24)

                        Text("Workout Access")
                            .font(.body)
                            .foregroundStyle(Color.gymText)

                        Spacer()

                        Text(authorizationStatusText)
                            .font(.subheadline)
                            .foregroundStyle(authorizationStatusColor)
                    }

                    if healthKitService.workoutAuthorizationStatus == .sharingDenied {
                        Button {
                            openHealthSettings()
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gymPrimary)
                        }
                        .padding(.top, AppSpacing.xs)
                    }

                    if healthKitService.workoutAuthorizationStatus == .notDetermined {
                        Button {
                            Task {
                                await requestAuthorization()
                            }
                        } label: {
                            HStack {
                                if isAuthorizing {
                                    ProgressView()
                                        .tint(Color.gymText)
                                } else {
                                    Image(systemName: "hand.tap")
                                }
                                Text("Set Up Now")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gymText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.component)
                            .background(Color.gymPrimary)
                            .cornerRadius(AppCornerRadius.button)
                        }
                        .disabled(isAuthorizing)
                        .padding(.top, AppSpacing.xs)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Body Weight Section

    private var bodyWeightSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Body Weight")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundStyle(Color.gymAccent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Latest from Health")
                            .font(.body)
                            .foregroundStyle(Color.gymText)

                        if let dateText = formattedWeightDate {
                            Text(dateText)
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }

                    Spacer()

                    if let weightText = formattedWeight {
                        Text(weightText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gymText)
                    } else {
                        Text("No data")
                            .font(.subheadline)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Historical Sync Section

    private var historicalSyncSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Historical Data")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                VStack(spacing: AppSpacing.component) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.gymPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Past Workouts")
                                .font(.body)
                                .foregroundStyle(Color.gymText)

                            Text("\(completedSessions.count) workout\(completedSessions.count == 1 ? "" : "s") available")
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)
                        }

                        Spacer()
                    }

                    if let result = syncResult {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.gymSuccess)

                            Text("\(result) workout\(result == 1 ? "" : "s") synced")
                                .font(.subheadline)
                                .foregroundStyle(Color.gymSuccess)

                            Spacer()
                        }
                    }

                    Button {
                        Task {
                            await syncHistoricalWorkouts()
                        }
                    } label: {
                        HStack {
                            if isSyncing {
                                ProgressView()
                                    .tint(Color.gymPrimary)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isSyncing ? "Syncing..." : "Sync Now")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.component)
                        .background(Color.gymPrimary.opacity(0.15))
                        .cornerRadius(AppCornerRadius.button)
                    }
                    .disabled(isSyncing || !healthKitService.canWriteWorkouts || completedSessions.isEmpty)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("About")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                VStack(alignment: .leading, spacing: AppSpacing.component) {
                    HStack(alignment: .top, spacing: AppSpacing.component) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.gymTextMuted)
                            .frame(width: 24)

                        Text("When enabled, GymTrack Pro will automatically save your completed workouts to Apple Health. Body weight data is read-only and will be displayed here if available.")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Settings Card Helper

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(AppSpacing.standard)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    // MARK: - Actions

    private func handleToggleChange(_ newValue: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if newValue {
            // Enabling - request authorization if needed
            if healthKitService.workoutAuthorizationStatus == .notDetermined {
                Task {
                    await requestAuthorization()
                }
            }
        }

        healthKitService.isEnabled = newValue
    }

    private func requestAuthorization() async {
        isAuthorizing = true
        defer { isAuthorizing = false }

        do {
            try await healthKitService.requestAuthorization()

            // Reload body weight after authorization
            await loadBodyWeight()
        } catch {
            alertTitle = "Authorization Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func loadBodyWeight() async {
        do {
            latestWeight = try await healthKitService.fetchLatestBodyWeight()
        } catch {
            // Silent failure for body weight
        }
    }

    private func syncHistoricalWorkouts() async {
        guard !completedSessions.isEmpty else { return }

        isSyncing = true
        syncResult = nil

        do {
            let count = try await healthKitService.syncHistoricalWorkouts(sessions: completedSessions)
            syncResult = count

            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            alertTitle = "Sync Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }

        isSyncing = false
    }

    private func openHealthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthKitSettingsView()
    }
    .modelContainer(for: [
        User.self,
        WorkoutSession.self,
        ExerciseLog.self,
        SetLog.self
    ], inMemory: true)
}
