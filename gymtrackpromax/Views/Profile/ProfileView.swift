//
//  ProfileView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Main profile view with settings and user statistics
struct ProfileView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query private var users: [User]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endTime != nil },
        sort: \WorkoutSession.startTime,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    // MARK: - State

    @State private var viewModel: ProfileViewModel?
    @State private var showingEditProfile: Bool = false
    @State private var showingClearDataAlert: Bool = false

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var weightUnit: WeightUnit {
        currentUser?.weightUnit ?? .kg
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            if let user = currentUser {
                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Profile Header
                        profileHeader(user: user)

                        // Stats Summary
                        statsSection

                        // Settings List
                        settingsSection(user: user)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            } else {
                noUserView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            if let user = currentUser {
                EditProfileView(user: user)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showingExportSheet ?? false },
            set: { viewModel?.showingExportSheet = $0 }
        )) {
            if let url = viewModel?.exportedCSVURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Data", role: .destructive) {
                viewModel?.clearAllData(user: currentUser)
            }
        } message: {
            Text("This will permanently delete all your workout history, personal records, and settings. This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel?.showingError ?? false },
            set: { viewModel?.showingError = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel?.errorMessage ?? "An error occurred")
        }
        .onAppear {
            setupViewModel()
        }
        .task {
            await viewModel?.loadLifetimeStats(user: currentUser, sessions: sessions)
        }
        .onChange(of: sessions.count) { _, _ in
            Task {
                await viewModel?.loadLifetimeStats(user: currentUser, sessions: sessions)
            }
        }
    }

    // MARK: - Profile Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: AppSpacing.component) {
            // Avatar
            ZStack {
                if let imageData = user.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gymPrimary)
                        .frame(width: 80, height: 80)

                    Text(userInitial(from: user.name))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymText)
                }
            }
            .accessibilityLabel("Profile avatar for \(user.name)")

            // Name
            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            // Member since
            Text("Member since \(viewModel?.formatMemberSince(user.createdAt) ?? "")")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)

            // Edit button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingEditProfile = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymPrimary)
            }
            .accessibilityLabel("Edit profile")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.standard)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Lifetime Stats")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.component) {
                ProfileStatCard(
                    title: "Total Workouts",
                    value: "\(viewModel?.lifetimeStats.totalWorkouts ?? 0)",
                    icon: "figure.strengthtraining.traditional",
                    color: Color.gymPrimary
                )

                ProfileStatCard(
                    title: "Current Streak",
                    value: "\(viewModel?.lifetimeStats.currentStreak ?? 0)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: Color.gymWarning
                )

                ProfileStatCard(
                    title: "Total PRs",
                    value: "\(viewModel?.lifetimeStats.totalPRs ?? 0)",
                    icon: "trophy.fill",
                    color: Color.gymSuccess
                )

                ProfileStatCard(
                    title: "Total Volume",
                    value: viewModel?.formatVolume(viewModel?.lifetimeStats.totalVolume ?? 0) ?? "0",
                    subtitle: weightUnit.symbol,
                    icon: "scalemass.fill",
                    color: Color.gymAccent
                )
            }
            .padding(.horizontal, AppSpacing.standard)

            // Longest streak callout
            if let longestStreak = viewModel?.lifetimeStats.longestStreak, longestStreak > 0 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.gymWarning)
                        .accessibilityHidden(true)

                    Text("Longest streak: \(longestStreak) days")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    // MARK: - Settings Section

    private func settingsSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Preferences
            settingsGroup(title: "Preferences") {
                // Workout Split - switches to Workout tab
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    NotificationCenter.default.post(name: .switchToWorkoutTab, object: nil)
                } label: {
                    SettingsRow(
                        icon: "calendar.badge.clock",
                        iconColor: Color.gymPrimary,
                        title: "Workout Split",
                        value: user.activeSplit?.name ?? "Not set"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .background(Color.gymBorder)

                // Weight Unit
                SettingsRow(
                    icon: "scalemass",
                    iconColor: Color.gymAccent,
                    title: "Weight Unit",
                    value: user.weightUnit.displayName
                )
                .overlay {
                    Menu {
                        ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                updateWeightUnit(user: user, unit: unit)
                            } label: {
                                HStack {
                                    Text(unit.displayName)
                                    if user.weightUnit == unit {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Color.clear
                    }
                    .accessibilityLabel("Change weight unit, currently \(user.weightUnit.displayName)")
                }

                Divider()
                    .background(Color.gymBorder)

                // Week Starts On
                SettingsRow(
                    icon: "calendar",
                    iconColor: Color.gymPrimary,
                    title: "Week Starts On",
                    value: user.weekStartDay.displayName
                )
                .overlay {
                    Menu {
                        ForEach(WeekStartDay.allCases, id: \.rawValue) { day in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                updateWeekStartDay(user: user, day: day)
                            } label: {
                                HStack {
                                    Text(day.displayName)
                                    if user.weekStartDay == day {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Color.clear
                    }
                    .accessibilityLabel("Change week start day, currently \(user.weekStartDay.displayName)")
                }

                Divider()
                    .background(Color.gymBorder)

                // Rest Timer Default
                SettingsRow(
                    icon: "timer",
                    iconColor: Color.gymSuccess,
                    title: "Default Rest Time",
                    value: viewModel?.formatRestTime(viewModel?.defaultRestTime ?? 90) ?? "90s"
                )
                .overlay {
                    Menu {
                        ForEach(viewModel?.restTimeOptions ?? [], id: \.self) { seconds in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel?.updateDefaultRestTime(seconds)
                            } label: {
                                HStack {
                                    Text(viewModel?.formatRestTime(seconds) ?? "\(seconds)s")
                                    if viewModel?.defaultRestTime == seconds {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Color.clear
                    }
                    .accessibilityLabel("Change default rest time, currently \(viewModel?.formatRestTime(viewModel?.defaultRestTime ?? 90) ?? "90s")")
                }

                Divider()
                    .background(Color.gymBorder)

                // Notifications
                Toggle(isOn: Binding(
                    get: { viewModel?.notificationsEnabled ?? false },
                    set: { viewModel?.toggleNotifications($0) }
                )) {
                    HStack(spacing: AppSpacing.component) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Color.gymWarning)
                            .frame(width: 24)

                        Text("Notifications")
                            .font(.body)
                            .foregroundStyle(Color.gymText)
                    }
                }
                .tint(Color.gymPrimary)
                .padding(.vertical, AppSpacing.small)
                .accessibilityHint("Toggle rest timer and workout reminder notifications")
            }

            // Data
            settingsGroup(title: "Data") {
                NavigationLink {
                    HealthKitSettingsView()
                } label: {
                    SettingsRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Apple Health",
                        value: HealthKitService.shared.isEnabled ? "On" : "Off"
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                NavigationLink {
                    CloudKitSettingsView()
                } label: {
                    SettingsRow(
                        icon: "icloud.fill",
                        iconColor: .blue,
                        title: "iCloud Sync",
                        value: CloudKitSyncService.shared.isEnabled ? "On" : "Off"
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel?.exportDataToCSV(user: currentUser, sessions: sessions)
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        iconColor: Color.gymPrimary,
                        title: "Export Data",
                        value: "CSV"
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingClearDataAlert = true
                } label: {
                    SettingsRow(
                        icon: "trash",
                        iconColor: Color.gymError,
                        title: "Clear All Data",
                        value: nil,
                        isDestructive: true
                    )
                }
            }

            // About
            settingsGroup(title: "About") {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    requestAppReview()
                } label: {
                    SettingsRow(
                        icon: "star",
                        iconColor: Color.gymWarning,
                        title: "Rate App",
                        value: nil
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    openHelpAndSupport()
                } label: {
                    SettingsRow(
                        icon: "questionmark.circle",
                        iconColor: Color.gymAccent,
                        title: "Help & Support",
                        value: nil
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    openPrivacyPolicy()
                } label: {
                    SettingsRow(
                        icon: "hand.raised",
                        iconColor: Color.gymTextMuted,
                        title: "Privacy Policy",
                        value: nil
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    openWebsite()
                } label: {
                    SettingsRow(
                        icon: "globe",
                        iconColor: Color.gymPrimary,
                        title: "Website",
                        value: nil
                    )
                }

                Divider()
                    .background(Color.gymBorder)

                SettingsRow(
                    icon: "info.circle",
                    iconColor: Color.gymTextMuted,
                    title: "Version",
                    value: "\(AppConstants.appVersion) (\(AppConstants.buildNumber))"
                )
            }

            // Developer
            settingsGroup(title: "Developer") {
                SettingsRow(
                    icon: "person.fill",
                    iconColor: Color.gymPrimary,
                    title: "Built by",
                    value: "Ashish"
                )

                Divider()
                    .background(Color.gymBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    openDeveloperInstagram()
                } label: {
                    SettingsRow(
                        icon: "camera",
                        iconColor: .purple,
                        title: "Instagram",
                        value: "@ashishalmighty"
                    )
                }
            }
        }
    }

    // MARK: - Settings Group

    private func settingsGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            VStack(spacing: 0) {
                content()
            }
            .padding(AppSpacing.standard)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - No User View

    private var noUserView: some View {
        VStack(spacing: AppSpacing.section) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(Color.gymTextMuted)

            Text("No Profile Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Please complete the onboarding process to set up your profile.")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)
        }
    }

    // MARK: - Helper Functions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ProfileViewModel(modelContext: modelContext)
        }
    }

    private func userInitial(from name: String) -> String {
        String(name.prefix(1)).uppercased()
    }

    private func updateWeightUnit(user: User, unit: WeightUnit) {
        user.weightUnit = unit
        try? modelContext.save()
    }

    private func updateWeekStartDay(user: User, day: WeekStartDay) {
        user.weekStartDay = day
        try? modelContext.save()
    }

    private func requestAppReview() {
        // In a real app, this would use StoreKit to request a review
        if let url = URL(string: "https://gymtrackprowebsite.vercel.app/") {
            openURL(url)
        }
    }

    private func openHelpAndSupport() {
        if let url = URL(string: "https://gymtrackprowebsite.vercel.app/") {
            openURL(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://gymtrackprowebsite.vercel.app/") {
            openURL(url)
        }
    }

    private func openWebsite() {
        if let url = URL(string: "https://gymtrackprowebsite.vercel.app/") {
            openURL(url)
        }
    }

    private func openDeveloperInstagram() {
        if let url = URL(string: "https://www.instagram.com/ashishalmighty/") {
            openURL(url)
        }
    }
}

// MARK: - Profile Stat Card

private struct ProfileStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(subtitle ?? "")")
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundStyle(isDestructive ? Color.gymError : Color.gymText)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }

            if !isDestructive && value != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .padding(.vertical, AppSpacing.small)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(value != nil ? ": \(value!)" : "")")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: [
            User.self,
            WorkoutSplit.self,
            WorkoutDay.self,
            Exercise.self,
            PlannedExercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self
        ], inMemory: true)
}
