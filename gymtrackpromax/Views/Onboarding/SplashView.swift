//
//  SplashView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Animated splash screen shown on first launch
struct SplashView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            // Logo
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color.gymPrimary)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            // App name
            Text("GymTrack Pro")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)
                .opacity(textOpacity)

            // Tagline
            Text("Your personal workout companion")
                .font(.title3)
                .foregroundStyle(Color.gymTextMuted)
                .opacity(taglineOpacity)

            Spacer()
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Logo scale and fade in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // App name fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }

        // Tagline fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            taglineOpacity = 1.0
        }

        // Auto-navigate after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                viewModel.goToNext()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        SplashView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
