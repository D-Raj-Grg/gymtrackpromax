//
//  GoalSelectionView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Step 2: Select fitness goal
struct GoalSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.component),
        GridItem(.flexible(), spacing: AppSpacing.component)
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and progress
            header

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Title
                    titleSection

                    // Goal grid
                    goalGrid
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.standard)
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
                currentStep: 2,
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
            Text("What's your main goal?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("We'll customize your experience")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Goal Grid

    private var goalGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.component) {
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                GoalCard(
                    goal: goal,
                    isSelected: viewModel.fitnessGoal == goal,
                    onTap: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                            viewModel.fitnessGoal = goal
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
        GoalSelectionView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
