//
//  SpotlightService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import CoreSpotlight
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Navigation destination from Spotlight search results
enum SpotlightDestination: Equatable {
    case exercise(UUID)
    case workoutSession(UUID)
}

/// Service for indexing exercises and workout sessions in iOS Spotlight search
@MainActor
final class SpotlightService {
    // MARK: - Singleton

    static let shared = SpotlightService()

    private init() {}

    // MARK: - Domain Identifiers

    private static let exerciseDomainID = "com.gymtrackpro.exercise"
    private static let sessionDomainID = "com.gymtrackpro.session"

    // MARK: - Index Exercises

    /// Batch-index all exercises for Spotlight search
    func indexAllExercises(_ exercises: [Exercise]) {
        let items = exercises.map { searchableItem(for: $0) }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                print("SpotlightService: Error indexing exercises: \(error)")
            } else {
                print("SpotlightService: Indexed \(items.count) exercises")
            }
        }
    }

    /// Index a single exercise
    func indexExercise(_ exercise: Exercise) {
        let item = searchableItem(for: exercise)
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                print("SpotlightService: Error indexing exercise: \(error)")
            }
        }
    }

    /// Remove an exercise from the Spotlight index
    func removeExerciseFromIndex(id: UUID) {
        let identifier = exerciseIdentifier(id)
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error {
                print("SpotlightService: Error removing exercise: \(error)")
            }
        }
    }

    // MARK: - Index Workout Sessions

    /// Index a completed workout session for Spotlight search
    func indexWorkoutSession(_ session: WorkoutSession) {
        let item = searchableItem(for: session)
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                print("SpotlightService: Error indexing session: \(error)")
            }
        }
    }

    /// Remove a workout session from the Spotlight index
    func removeSessionFromIndex(id: UUID) {
        let identifier = sessionIdentifier(id)
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error {
                print("SpotlightService: Error removing session: \(error)")
            }
        }
    }

    // MARK: - Handle Search Result

    /// Parse a Spotlight user activity into a navigation destination
    func handleSearchResult(_ userActivity: NSUserActivity) -> SpotlightDestination? {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }

        if identifier.hasPrefix(Self.exerciseDomainID + ".") {
            let uuidString = String(identifier.dropFirst(Self.exerciseDomainID.count + 1))
            if let uuid = UUID(uuidString: uuidString) {
                return .exercise(uuid)
            }
        } else if identifier.hasPrefix(Self.sessionDomainID + ".") {
            let uuidString = String(identifier.dropFirst(Self.sessionDomainID.count + 1))
            if let uuid = UUID(uuidString: uuidString) {
                return .workoutSession(uuid)
            }
        }

        return nil
    }

    // MARK: - Private Helpers

    private func exerciseIdentifier(_ id: UUID) -> String {
        "\(Self.exerciseDomainID).\(id.uuidString)"
    }

    private func sessionIdentifier(_ id: UUID) -> String {
        "\(Self.sessionDomainID).\(id.uuidString)"
    }

    private func searchableItem(for exercise: Exercise) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = exercise.name
        attributes.contentDescription = "\(exercise.primaryMuscle.displayName) - \(exercise.equipment.displayName)"
        attributes.keywords = [
            exercise.name,
            exercise.primaryMuscle.displayName,
            exercise.equipment.displayName
        ] + exercise.secondaryMuscles.map { $0.displayName }

        return CSSearchableItem(
            uniqueIdentifier: exerciseIdentifier(exercise.id),
            domainIdentifier: Self.exerciseDomainID,
            attributeSet: attributes
        )
    }

    private func searchableItem(for session: WorkoutSession) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)

        let dateString = session.startTime.formatted(date: .abbreviated, time: .omitted)

        attributes.title = "\(session.workoutName) - \(dateString)"

        let exerciseNames = session.exerciseLogs
            .compactMap { $0.exercise?.name }
            .joined(separator: ", ")

        attributes.contentDescription = [
            exerciseNames,
            session.durationDisplay,
            "\(session.totalVolumeDisplay) kg volume"
        ].joined(separator: " | ")

        attributes.keywords = [
            session.workoutName,
            dateString
        ] + session.exerciseLogs.compactMap { $0.exercise?.name }

        return CSSearchableItem(
            uniqueIdentifier: sessionIdentifier(session.id),
            domainIdentifier: Self.sessionDomainID,
            attributeSet: attributes
        )
    }
}
