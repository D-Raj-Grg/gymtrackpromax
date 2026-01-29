//
//  WelcomeCarouselView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Welcome carousel with feature highlights
struct WelcomeCarouselView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var currentPage: Int = 0

    private let slides: [(icon: String, color: Color, title: String, description: String)] = [
        (
            "figure.strengthtraining.traditional",
            .gymPrimary,
            "Track Your Workouts",
            "Log every set, rep, and weight with ease. Your workout history is always at your fingertips."
        ),
        (
            "calendar.badge.checkmark",
            .gymAccent,
            "Follow Your Plan",
            "Choose from proven workout splits or create your own. Never wonder what to train again."
        ),
        (
            "chart.line.uptrend.xyaxis",
            .gymSuccess,
            "See Your Progress",
            "Watch your strength grow with detailed charts and personal records tracking."
        )
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.goToNext()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.small)
            }

            // Carousel
            TabView(selection: $currentPage) {
                ForEach(0..<slides.count, id: \.self) { index in
                    CarouselSlideView(
                        icon: slides[index].icon,
                        iconColor: slides[index].color,
                        title: slides[index].title,
                        description: slides[index].description
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators and buttons
            VStack(spacing: AppSpacing.section) {
                // Custom page indicators
                HStack(spacing: AppSpacing.small) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.gymPrimary : Color.gymCardHover)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: AppAnimation.quick), value: currentPage)
                    }
                }

                // Action buttons
                VStack(spacing: AppSpacing.component) {
                    if currentPage == slides.count - 1 {
                        // Get Started button on last slide
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.goToNext()
                        } label: {
                            Text("Get Started")
                        }
                        .primaryButtonStyle()
                    } else {
                        // Next button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                        }
                        .primaryButtonStyle()
                    }
                }
                .padding(.horizontal, AppSpacing.standard)
            }
            .padding(.bottom, AppSpacing.large)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        WelcomeCarouselView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
