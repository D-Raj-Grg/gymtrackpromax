//
//  CarouselSlideView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Reusable carousel slide component for onboarding
struct CarouselSlideView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            // Icon with background circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: icon)
                    .font(.system(size: 70))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: AppSpacing.component) {
                // Title
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(.body)
                    .foregroundStyle(Color.gymTextMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.section)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.standard)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        CarouselSlideView(
            icon: "figure.strengthtraining.traditional",
            iconColor: .gymPrimary,
            title: "Track Your Workouts",
            description: "Log every set, rep, and weight with ease. See your progress over time."
        )
    }
    .preferredColorScheme(.dark)
}
