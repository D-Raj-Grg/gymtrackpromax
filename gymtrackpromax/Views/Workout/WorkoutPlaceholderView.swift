//
//  WorkoutPlaceholderView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct WorkoutPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.section) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.gymPrimary)

                Text("Workout")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text("Start and track your workouts here")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .multilineTextAlignment(.center)

                Text("Coming in Milestone 1.4")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
                    .padding(.top, AppSpacing.standard)
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutPlaceholderView()
}
