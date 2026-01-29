//
//  UserInfoView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Step 1: Collect user name, unit preference, and experience level
struct UserInfoView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and progress
            header

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Title
                    titleSection

                    // Name input
                    nameSection

                    // Unit selection
                    unitSection

                    // Week start day
                    weekStartSection

                    // Experience level
                    experienceSection
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.standard)
            }

            // Continue button
            continueButton
        }
        .onTapGesture {
            isNameFocused = false
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.gymText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            OnboardingProgressBar(
                currentStep: 1,
                totalSteps: OnboardingStep.totalSteps
            )

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.small)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Let's get started")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Tell us a bit about yourself")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Name Input

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("What should we call you?")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.gymText)

            TextField("Enter your name", text: $viewModel.userName)
                .textContentType(.name)
                .autocorrectionDisabled()
                .focused($isNameFocused)
                .font(.body)
                .foregroundStyle(Color.gymText)
                .inputFieldStyle(isFocused: isNameFocused)
        }
    }

    // MARK: - Unit Selection

    private var unitSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Preferred weight unit")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.gymText)

            Picker("Weight Unit", selection: $viewModel.weightUnit) {
                Text("kg").tag(WeightUnit.kg)
                Text("lbs").tag(WeightUnit.lbs)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Week Start Day

    private var weekStartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Week starts on")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.gymText)

            Picker("Week Start Day", selection: $viewModel.weekStartDay) {
                Text("Mon").tag(WeekStartDay.monday)
                Text("Sun").tag(WeekStartDay.sunday)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Experience Level

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Experience level")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.gymText)

            VStack(spacing: AppSpacing.component) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    ExperienceLevelCard(
                        level: level,
                        isSelected: viewModel.experienceLevel == level,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.experienceLevel = level
                            // Update recommended split
                            viewModel.selectedSplit = viewModel.recommendedSplit(for: level)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isNameFocused = false
                viewModel.goToNext()
            } label: {
                Text("Continue")
            }
            .primaryButtonStyle(isEnabled: viewModel.isUserInfoValid)
            .disabled(!viewModel.isUserInfoValid)
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.standard)
        .background(Color.gymBackground)
    }
}

// MARK: - Experience Level Card

private struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.component) {
                // Selection indicator
                Circle()
                    .strokeBorder(isSelected ? Color.gymPrimary : Color.gymBorder, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.gymPrimary : Color.clear)
                            .padding(4)
                    )
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.gymText)

                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()
            }
            .padding(AppSpacing.standard)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isSelected ? Color.gymPrimary : Color.gymBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        UserInfoView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
