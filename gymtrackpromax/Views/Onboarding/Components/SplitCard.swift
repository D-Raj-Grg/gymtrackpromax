//
//  SplitCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Selectable card for workout split selection
struct SplitCard: View {
    let splitType: SplitType
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.component) {
                // Header with badges
                HStack {
                    // Days per week badge
                    Text("\(splitType.daysPerWeek) days/week")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, 4)
                        .background(Color.gymCardHover)
                        .clipShape(Capsule())

                    Spacer()

                    // Split badge (Most Popular, Beginner Friendly, etc.)
                    if let badge = splitType.badge {
                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(badgeColor)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, 4)
                            .background(badgeColor.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    // Recommended badge
                    if isRecommended && splitType.badge == nil {
                        Text("Recommended")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.gymSuccess)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, 4)
                            .background(Color.gymSuccess.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                // Split name
                Text(splitType.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.gymText)

                // Description
                Text(splitType.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Day names preview
                if !splitType.defaultDayNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(Array(Set(splitType.defaultDayNames)).sorted(), id: \.self) { dayName in
                                Text(dayName)
                                    .font(.caption)
                                    .foregroundStyle(Color.gymTextMuted)
                                    .padding(.horizontal, AppSpacing.small)
                                    .padding(.vertical, 2)
                                    .background(Color.gymBackground)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isSelected ? Color.gymPrimary : Color.gymBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Badge Color

    private var badgeColor: Color {
        switch splitType.badge {
        case "Most Popular":
            return .gymPrimary
        case "Beginner Friendly":
            return .gymSuccess
        case "Advanced":
            return .gymWarning
        case "Classic":
            return .gymAccent
        default:
            return .gymTextMuted
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: AppSpacing.component) {
                SplitCard(splitType: .ppl, isSelected: true, isRecommended: false, onTap: {})
                SplitCard(splitType: .fullBody, isSelected: false, isRecommended: true, onTap: {})
                SplitCard(splitType: .arnoldSplit, isSelected: false, isRecommended: false, onTap: {})
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
