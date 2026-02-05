//
//  CloudKitSettingsView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 05/02/26.
//

import SwiftUI
import CloudKit

/// Settings view for iCloud (CloudKit) sync configuration
struct CloudKitSettingsView: View {
    // MARK: - Environment

    @Environment(\.openURL) private var openURL

    // MARK: - State

    @State private var isEnabled: Bool = CloudKitSyncService.shared.isEnabled
    @State private var accountStatus: CKAccountStatus?
    @State private var isCheckingAccount: Bool = false
    @State private var showingRestartAlert: Bool = false

    // MARK: - Computed Properties

    private var cloudKitService: CloudKitSyncService { CloudKitSyncService.shared }

    private var accountStatusText: String {
        guard let status = accountStatus else {
            return "Checking..."
        }
        return cloudKitService.accountStatusDescription(status)
    }

    private var accountStatusColor: Color {
        guard let status = accountStatus else {
            return Color.gymTextMuted
        }
        switch status {
        case .available:
            return Color.gymSuccess
        case .noAccount, .restricted:
            return Color.gymError
        default:
            return Color.gymTextMuted
        }
    }

    private var lastSyncText: String? {
        guard let date = cloudKitService.lastSyncDate else {
            return nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var syncStatusText: String {
        cloudKitService.syncStatus.displayText
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Enable/Disable toggle
                    toggleSection

                    if isEnabled {
                        // Account status
                        accountSection

                        // Sync status
                        syncStatusSection
                    }

                    // Info section
                    infoSection

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.top, AppSpacing.standard)
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("iCloud Sync")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
            }
        }
        .alert("Restart Required", isPresented: $showingRestartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please restart the app for iCloud sync changes to take effect.")
        }
        .task {
            await checkAccountStatus()
        }
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            settingsCard {
                Toggle(isOn: $isEnabled) {
                    HStack(spacing: AppSpacing.component) {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with iCloud")
                                .font(.body)
                                .foregroundStyle(Color.gymText)

                            Text("Keep data in sync across devices")
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

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("iCloud Account")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                VStack(spacing: AppSpacing.component) {
                    HStack {
                        Image(systemName: accountStatus == .available ? "checkmark.icloud.fill" : "xmark.icloud")
                            .foregroundStyle(accountStatusColor)
                            .frame(width: 24)

                        Text("Account Status")
                            .font(.body)
                            .foregroundStyle(Color.gymText)

                        Spacer()

                        if isCheckingAccount {
                            ProgressView()
                                .tint(Color.gymTextMuted)
                        } else {
                            Text(accountStatusText)
                                .font(.subheadline)
                                .foregroundStyle(accountStatusColor)
                        }
                    }

                    if accountStatus == .noAccount {
                        Button {
                            openSettings()
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
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Sync Status")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            settingsCard {
                VStack(spacing: AppSpacing.component) {
                    HStack {
                        if cloudKitService.syncStatus.isActive {
                            ProgressView()
                                .tint(Color.gymAccent)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(Color.gymSuccess)
                                .frame(width: 24)
                        }

                        Text("Status")
                            .font(.body)
                            .foregroundStyle(Color.gymText)

                        Spacer()

                        Text(syncStatusText)
                            .font(.subheadline)
                            .foregroundStyle(Color.gymTextMuted)
                    }

                    if let lastSync = lastSyncText {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(Color.gymTextMuted)
                                .frame(width: 24)

                            Text("Last Synced")
                                .font(.body)
                                .foregroundStyle(Color.gymText)

                            Spacer()

                            Text(lastSync)
                                .font(.subheadline)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }
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
                    infoRow(
                        icon: "arrow.triangle.2.circlepath",
                        text: "Syncs workouts, exercises, PRs, and settings across all your devices."
                    )

                    infoRow(
                        icon: "lock.shield",
                        text: "Data is stored securely in your private iCloud account."
                    )

                    infoRow(
                        icon: "exclamationmark.triangle",
                        text: "Enabling or disabling sync requires an app restart."
                    )
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Info Row Helper

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.component) {
            Image(systemName: icon)
                .foregroundStyle(Color.gymTextMuted)
                .frame(width: 24)

            Text(text)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
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
        cloudKitService.isEnabled = newValue
        showingRestartAlert = true
    }

    private func checkAccountStatus() async {
        isCheckingAccount = true
        defer { isCheckingAccount = false }

        do {
            accountStatus = try await cloudKitService.checkAccountStatus()
        } catch {
            accountStatus = .couldNotDetermine
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CloudKitSettingsView()
    }
}
