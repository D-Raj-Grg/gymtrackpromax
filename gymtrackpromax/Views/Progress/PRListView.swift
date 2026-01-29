//
//  PRListView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct PRListView: View {
    // MARK: - Properties

    let records: [PRRecord]
    let weightUnit: WeightUnit

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.component) {
            if records.isEmpty {
                emptyState
            } else {
                ForEach(records) { record in
                    PRCard(record: record, weightUnit: weightUnit)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView.noPRs()
    }
}

// MARK: - Preview

#Preview {
    let exercise1 = Exercise(
        name: "Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )

    let exercise2 = Exercise(
        name: "Squat",
        primaryMuscle: .quads,
        secondaryMuscles: [.glutes, .hamstrings],
        equipment: .barbell
    )

    let records = [
        PRRecord(
            exercise: exercise1,
            weight: 100,
            reps: 5,
            estimated1RM: 116.67,
            date: Date(),
            sessionId: nil
        ),
        PRRecord(
            exercise: exercise2,
            weight: 140,
            reps: 3,
            estimated1RM: 154,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            sessionId: nil
        )
    ]

    return ScrollView {
        PRListView(records: records, weightUnit: .kg)
            .padding()
    }
    .background(Color.gymBackground)
}
