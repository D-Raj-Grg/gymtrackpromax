//
//  OnboardingProgressBar.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Progress indicator showing current step in onboarding
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            // Step text
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            // Progress dots
            HStack(spacing: AppSpacing.small) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.gymPrimary : Color.gymCardHover)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            OnboardingProgressBar(currentStep: 1, totalSteps: 4)
            OnboardingProgressBar(currentStep: 2, totalSteps: 4)
            OnboardingProgressBar(currentStep: 3, totalSteps: 4)
            OnboardingProgressBar(currentStep: 4, totalSteps: 4)
        }
    }
    .preferredColorScheme(.dark)
}
