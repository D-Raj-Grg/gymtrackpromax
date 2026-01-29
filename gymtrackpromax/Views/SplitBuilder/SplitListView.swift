//
//  SplitListView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// View to list all workout splits, switch active, create new
struct SplitListView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var users: [User]

    // MARK: - State

    @State private var viewModel: SplitBuilderViewModel?
    @State private var showingCreateSplit: Bool = false
    @State private var showingTemplateSelection: Bool = false
    @State private var selectedTemplate: SplitType?
    @State private var splitToEdit: WorkoutSplit?
    @State private var showingDeleteAlert: Bool = false
    @State private var splitToDelete: WorkoutSplit?
    @State private var showingActivateAlert: Bool = false
    @State private var splitToActivate: WorkoutSplit?

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var splits: [WorkoutSplit] {
        currentUser?.workoutSplits.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    private var activeSplit: WorkoutSplit? {
        currentUser?.activeSplit
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            if splits.isEmpty {
                emptyState
            } else {
                splitsList
            }
        }
        .navigationTitle("Workout Splits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingTemplateSelection = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .sheet(isPresented: $showingTemplateSelection) {
            SplitTemplateSelectionView(
                onSelectTemplate: { template in
                    selectedTemplate = template
                    showingTemplateSelection = false
                    if template == .custom {
                        showingCreateSplit = true
                    } else {
                        // Navigate to template customization
                        showingCreateSplit = true
                    }
                },
                onSelectCustom: {
                    showingTemplateSelection = false
                    showingCreateSplit = true
                }
            )
        }
        .sheet(isPresented: $showingCreateSplit) {
            if let template = selectedTemplate, template != .custom {
                CustomSplitBuilderView(templateType: template)
            } else {
                CustomSplitBuilderView()
            }
        }
        .onChange(of: showingCreateSplit) { _, isShowing in
            if !isShowing {
                selectedTemplate = nil
            }
        }
        .sheet(item: $splitToEdit) { split in
            CustomSplitBuilderView(existingSplit: split)
        }
        .alert("Delete Split?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let split = splitToDelete {
                    deleteSplit(split)
                }
                splitToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                splitToDelete = nil
            }
        } message: {
            Text("This will permanently delete the split and all its workout days. This action cannot be undone.")
        }
        .alert("Set as Active Split?", isPresented: $showingActivateAlert) {
            Button("Activate", role: .none) {
                if let split = splitToActivate {
                    setActiveSplit(split)
                }
                splitToActivate = nil
            }
            Button("Cancel", role: .cancel) {
                splitToActivate = nil
            }
        } message: {
            if let split = splitToActivate {
                Text("\"\(split.name)\" will become your active workout split and appear on your dashboard.")
            } else {
                Text("This split will become your active workout split.")
            }
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Color.gymTextMuted)

            Text("No Workout Splits")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Create a workout split to organize your training schedule")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingCreateSplit = true
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Split")
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.section)
                .padding(.vertical, AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .fill(Color.gymPrimary)
                )
            }

            Spacer()
        }
    }

    // MARK: - Splits List

    private var splitsList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Info section
                infoSection

                // Active Split Section
                if let active = activeSplit {
                    activeSplitSection(split: active)
                }

                // All Splits
                allSplitsSection
            }
            .padding(.vertical, AppSpacing.standard)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: "info.circle.fill")
                .font(.body)
                .foregroundStyle(Color.gymPrimary)

            Text("Your active split determines which workouts appear on your dashboard. Tap a split to edit it.")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymPrimary.opacity(0.1))
        )
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Active Split Section

    private func activeSplitSection(split: WorkoutSplit) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Active Split")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            SplitListRow(
                split: split,
                isActive: true,
                onTap: {
                    splitToEdit = split
                },
                onSetActive: nil,
                onDelete: nil
            )
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - All Splits Section

    private var allSplitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("All Splits")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text("\(splits.count)")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.standard)

            // Use List for swipe actions to work
            List {
                ForEach(splits) { split in
                    if split.id != activeSplit?.id {
                        SplitListRow(
                            split: split,
                            isActive: false,
                            onTap: {
                                splitToEdit = split
                            },
                            onSetActive: {
                                splitToActivate = split
                                showingActivateAlert = true
                            },
                            onDelete: {
                                splitToDelete = split
                                showingDeleteAlert = true
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.standard, bottom: 4, trailing: AppSpacing.standard))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(minHeight: CGFloat(splits.filter { $0.id != activeSplit?.id }.count) * 120)
        }
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = SplitBuilderViewModel(modelContext: modelContext)
        }
    }

    private func setActiveSplit(_ split: WorkoutSplit) {
        guard let user = currentUser else { return }

        viewModel?.setActiveSplit(split, user: user)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func deleteSplit(_ split: WorkoutSplit) {
        guard let viewModel = viewModel else { return }

        do {
            try viewModel.deleteSplit(split)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            viewModel.showError(error.localizedDescription)
        }
    }
}

// MARK: - Split Template Card

private struct SplitTemplateCard: View {
    let template: SplitType
    let onSelect: () -> Void

    private var icon: String {
        switch template {
        case .ppl: return "arrow.left.arrow.right"
        case .upperLower: return "arrow.up.arrow.down"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .broSplit: return "dumbbell.fill"
        case .arnoldSplit: return "star.fill"
        case .ulPpl: return "arrow.up.arrow.down.circle"
        case .pplUl: return "arrow.left.arrow.right.circle"
        default: return "calendar"
        }
    }

    private var color: Color {
        switch template {
        case .ppl: return .gymPrimary
        case .upperLower: return .gymAccent
        case .fullBody: return .gymSuccess
        case .broSplit: return .gymWarning
        case .arnoldSplit: return Color(hex: 0xF97316)
        case .ulPpl: return Color(hex: 0x8B5CF6) // Purple
        case .pplUl: return Color(hex: 0xEC4899) // Pink
        default: return .gymPrimary
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))

                // Title
                Text(template.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
                    .lineLimit(1)

                // Days badge
                HStack(spacing: AppSpacing.xs) {
                    Text("\(template.daysPerWeek) days")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)

                    if let badge = template.badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.component)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Split Template Selection View

private struct SplitTemplateSelectionView: View {
    let onSelectTemplate: (SplitType) -> Void
    let onSelectCustom: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let templates: [SplitType] = [.ppl, .upperLower, .fullBody, .broSplit, .arnoldSplit, .ulPpl, .pplUl]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Header text
                    Text("Choose a template to get started quickly, or build your own custom split.")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.standard)

                    // Template Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AppSpacing.component),
                        GridItem(.flexible(), spacing: AppSpacing.component)
                    ], spacing: AppSpacing.component) {
                        ForEach(templates, id: \.self) { template in
                            SplitTemplateCard(template: template) {
                                onSelectTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.standard)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gymBorder)
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)
                        Rectangle()
                            .fill(Color.gymBorder)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, AppSpacing.standard)

                    // Custom Button
                    Button(action: onSelectCustom) {
                        HStack(spacing: AppSpacing.component) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(Color.gymPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Custom Split")
                                    .font(.headline)
                                    .foregroundStyle(Color.gymText)

                                Text("Build your own from scratch")
                                    .font(.caption)
                                    .foregroundStyle(Color.gymTextMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.gymTextMuted)
                        }
                        .padding(AppSpacing.standard)
                        .background(Color.gymCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.standard)
                }
                .padding(.vertical, AppSpacing.standard)
            }
            .background(Color.gymBackground)
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.gymPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SplitListView()
    }
    .modelContainer(for: [
        User.self,
        WorkoutSplit.self,
        WorkoutDay.self,
        Exercise.self,
        PlannedExercise.self
    ], inMemory: true)
}
