//
//  SplitSelectionView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Step 3: Select workout split
struct SplitSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    // Filter out custom split for onboarding
    private var availableSplits: [SplitType] {
        SplitType.allCases.filter { $0 != .custom }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and progress
            header

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Title
                    titleSection

                    // Split cards
                    splitList
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.standard)
                .padding(.bottom, AppSpacing.section)
            }

            // Continue button
            continueButton
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
                currentStep: 3,
                totalSteps: OnboardingStep.totalSteps
            )

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.small)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Choose your split")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Pick a workout routine that fits your schedule")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Split List

    private var splitList: some View {
        VStack(spacing: AppSpacing.component) {
            ForEach(availableSplits, id: \.self) { splitType in
                SplitCard(
                    splitType: splitType,
                    isSelected: viewModel.selectedSplit == splitType,
                    isRecommended: splitType == viewModel.recommendedSplit(for: viewModel.experienceLevel),
                    onTap: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                            viewModel.selectedSplit = splitType
                            viewModel.setDefaultWeekdays()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.goToNext()
            } label: {
                Text("Continue")
            }
            .primaryButtonStyle()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.standard)
        .background(Color.gymBackground)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        SplitSelectionView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
