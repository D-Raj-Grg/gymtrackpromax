//
//  ProfilePlaceholderView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct ProfilePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.section) {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.gymPrimary)

                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text("Manage your profile and settings")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .multilineTextAlignment(.center)

                Text("Coming in Milestone 1.7")
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
    ProfilePlaceholderView()
}
