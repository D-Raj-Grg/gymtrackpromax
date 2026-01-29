//
//  OnboardingContainerView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Root container view for the onboarding flow
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            switch viewModel.currentStep {
            case .splash:
                SplashView(viewModel: viewModel)
                    .transition(.opacity)

            case .welcome:
                WelcomeCarouselView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .userInfo:
                UserInfoView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .goalSelection:
                GoalSelectionView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .splitSelection:
                SplitSelectionView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .scheduleCustomization:
                ScheduleCustomizationView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .complete:
                OnboardingCompleteView(viewModel: viewModel, onComplete: onComplete)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: AppAnimation.standard), value: viewModel.currentStep)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView(onComplete: {})
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
