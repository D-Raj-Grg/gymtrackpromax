//
//  ConfettiView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI

/// Animated confetti particle effect
struct ConfettiView: View {
    // MARK: - Properties

    let isActive: Bool

    // MARK: - State

    @State private var particles: [ConfettiParticle] = []
    @State private var animationStartTime: Date?

    // MARK: - Constants

    private let particleCount = 50
    private let colors: [Color] = [
        .gymPrimary,
        .gymAccent,
        .gymSuccess,
        .gymWarning,
        Color.pink,
        Color.orange
    ]

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                guard let startTime = animationStartTime else { return }
                let elapsed = timeline.date.timeIntervalSince(startTime)

                for particle in particles {
                    let progress = elapsed - particle.delay
                    guard progress > 0 else { continue }

                    let gravity: Double = 200
                    let x = particle.startX * size.width + particle.driftX * progress
                    let y = particle.startY * size.height + particle.velocityY * progress + 0.5 * gravity * progress * progress
                    let rotation = Angle.degrees(particle.rotationSpeed * progress * 360)
                    let opacity = max(0, 1.0 - progress / 3.0)

                    guard y < size.height + 20, opacity > 0 else { continue }

                    var transform = context
                    transform.translateBy(x: x, y: y)
                    transform.rotate(by: rotation)
                    transform.opacity = opacity

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * particle.aspectRatio
                    )

                    transform.fill(
                        Path(roundedRect: rect, cornerRadius: particle.size * 0.2),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                generateParticles()
                animationStartTime = Date()
            }
        }
        .onAppear {
            if isActive {
                generateParticles()
                animationStartTime = Date()
            }
        }
    }

    // MARK: - Particle Generation

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                startX: Double.random(in: 0.1...0.9),
                startY: Double.random(in: -0.2...0.0),
                velocityY: Double.random(in: -150...(-50)),
                driftX: Double.random(in: -40...40),
                rotationSpeed: Double.random(in: 0.5...2.0),
                size: Double.random(in: 6...12),
                aspectRatio: Double.random(in: 0.5...2.0),
                color: colors.randomElement() ?? .gymPrimary,
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

// MARK: - Confetti Particle

private struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let velocityY: Double
    let driftX: Double
    let rotationSpeed: Double
    let size: Double
    let aspectRatio: Double
    let color: Color
    let delay: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        ConfettiView(isActive: true)
    }
}
