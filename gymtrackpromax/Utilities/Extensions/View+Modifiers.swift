//
//  View+Modifiers.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import SwiftUI

// MARK: - Card Style

extension View {
    /// Applies card styling with background, corner radius, and optional shadow
    func cardStyle(padding: CGFloat = AppSpacing.card) -> some View {
        self
            .padding(padding)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    /// Applies a larger card style
    func cardStyleLarge(padding: CGFloat = AppSpacing.card) -> some View {
        self
            .padding(padding)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge))
    }

    /// Applies card with border
    func cardStyleBordered(padding: CGFloat = AppSpacing.card) -> some View {
        self
            .padding(padding)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.gymBorder, lineWidth: 1)
            )
    }
}

// MARK: - Button Styles

/// Primary button style with filled background
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.gymText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.standard)
            .background(
                isEnabled
                    ? (configuration.isPressed ? Color.gymPrimaryLight : Color.gymPrimary)
                    : Color.gymCardHover
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AppAnimation.quick), value: configuration.isPressed)
    }
}

/// Secondary button style with border
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.gymPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.standard)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .stroke(Color.gymPrimary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: AppAnimation.quick), value: configuration.isPressed)
    }
}

/// Ghost button style (text only)
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.gymTextMuted)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: AppAnimation.quick), value: configuration.isPressed)
    }
}

/// Icon button style
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                configuration.isPressed ? Color.gymCardHover : Color.gymCard
            )
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: AppAnimation.quick), value: configuration.isPressed)
    }
}

// MARK: - View Extension for Button Styles

extension View {
    /// Applies primary button style
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }

    /// Applies secondary button style
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }

    /// Applies ghost button style
    func ghostButtonStyle() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }

    /// Applies icon button style
    func iconButtonStyle(size: CGFloat = 44) -> some View {
        self.buttonStyle(IconButtonStyle(size: size))
    }
}

// MARK: - Input Field Style

extension View {
    /// Applies input field styling
    func inputFieldStyle() -> some View {
        self
            .padding(AppSpacing.standard)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                    .stroke(Color.gymBorder, lineWidth: 1)
            )
    }

    /// Applies focused input field styling
    func inputFieldStyle(isFocused: Bool) -> some View {
        self
            .padding(AppSpacing.standard)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                    .stroke(isFocused ? Color.gymPrimary : Color.gymBorder, lineWidth: isFocused ? 2 : 1)
            )
    }
}

// MARK: - Shimmer Effect

extension View {
    /// Adds a shimmer/loading effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally applies one of two modifiers
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    /// Adds haptic feedback on tap
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            HapticManager.impact(style)
        }
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// Applies standard accessibility configuration with label and hint
    func standardAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    /// Makes the view accessible as a button with label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    /// Makes the view accessible as a header
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Makes the view accessible as an image with a description
    func accessibleImage(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }

    /// Hides the view from accessibility
    func accessibilityHiddenCompletely() -> some View {
        self.accessibilityHidden(true)
    }

    /// Makes a card accessible with combined children
    func accessibleCard(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    /// Adds a value description for accessibility (useful for stats, progress)
    func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }
}

// MARK: - Focus State Helpers

extension View {
    /// Scrolls to this view when it becomes focused
    @ViewBuilder
    func scrollOnFocus<V: Hashable>(id: V, anchor: UnitPoint = .center) -> some View {
        self.id(id)
    }
}

// MARK: - Animation Helpers

extension View {
    /// Applies spring animation to changes
    func springAnimation() -> some View {
        self.animation(AppAnimation.spring, value: UUID())
    }

    /// Applies standard fade animation
    func fadeAnimation() -> some View {
        self.animation(.easeInOut(duration: AppAnimation.standard), value: UUID())
    }
}

// MARK: - Safe Area Helpers

extension View {
    /// Adds bottom padding equal to safe area (for scroll views)
    func bottomSafeAreaPadding() -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension View {
    /// Adds a colored border for debugging layout
    func debugBorder(_ color: Color = .red) -> some View {
        self.border(color, width: 1)
    }

    /// Prints when this view's body is evaluated
    func debugPrint(_ message: String) -> some View {
        print("DEBUG: \(message)")
        return self
    }
}
#endif
