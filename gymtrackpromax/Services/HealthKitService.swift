//
//  HealthKitService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import Foundation
import HealthKit
import SwiftData

/// Service for managing Apple HealthKit integration
@MainActor
final class HealthKitService {
    // MARK: - Singleton

    static let shared = HealthKitService()

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    /// Whether HealthKit sync is enabled by the user
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "healthKitEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "healthKitEnabled") }
    }

    /// Whether the device supports HealthKit
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Types we want to read from HealthKit
    private var typesToRead: Set<HKObjectType> {
        guard let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }
        return [bodyMass]
    }

    /// Types we want to write to HealthKit
    private var typesToWrite: Set<HKSampleType> {
        return [HKObjectType.workoutType()]
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    /// Current authorization status for workouts
    var workoutAuthorizationStatus: HKAuthorizationStatus {
        healthStore.authorizationStatus(for: HKObjectType.workoutType())
    }

    /// Current authorization status for body mass reading
    var bodyMassAuthorizationStatus: HKAuthorizationStatus {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: bodyMassType)
    }

    /// Whether we have authorization to write workouts
    var canWriteWorkouts: Bool {
        workoutAuthorizationStatus == .sharingAuthorized
    }

    /// Request authorization for HealthKit access
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }

    // MARK: - Write Workouts

    /// Save a completed workout session to HealthKit
    func saveWorkout(_ session: WorkoutSession) async throws {
        guard isEnabled else { return }
        guard canWriteWorkouts else {
            throw HealthKitError.notAuthorized
        }
        guard session.isCompleted, let endTime = session.endTime else {
            throw HealthKitError.invalidSession
        }

        // Calculate estimated calories (approximately 4.5 cal/minute for strength training)
        let durationMinutes = session.duration.map { $0 / 60 } ?? 0
        let estimatedCalories = durationMinutes * 4.5

        // Create metadata
        var metadata: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "GymTrack Pro",
            "WorkoutName": session.workoutName,
            "ExerciseCount": session.exerciseLogs.count,
            "TotalSets": session.totalSets,
            "TotalVolume": session.totalVolume
        ]

        if let notes = session.notes {
            metadata["Notes"] = notes
        }

        // Create the workout
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: session.startTime,
            end: endTime,
            duration: session.duration ?? 0,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories),
            totalDistance: nil,
            metadata: metadata
        )

        // Save to HealthKit
        try await healthStore.save(workout)
    }

    /// Sync historical workouts to HealthKit
    /// Returns the number of workouts successfully synced
    func syncHistoricalWorkouts(sessions: [WorkoutSession]) async throws -> Int {
        guard isEnabled else { return 0 }
        guard canWriteWorkouts else {
            throw HealthKitError.notAuthorized
        }

        var syncedCount = 0

        for session in sessions {
            guard session.isCompleted else { continue }

            do {
                // Check if workout already exists
                let alreadyExists = try await workoutExists(startDate: session.startTime)
                if !alreadyExists {
                    try await saveWorkout(session)
                    syncedCount += 1
                }
            } catch {
                // Continue with next workout if one fails
                continue
            }
        }

        return syncedCount
    }

    /// Check if a workout with the given start date already exists
    private func workoutExists(startDate: Date) async throws -> Bool {
        // Query for workouts within 1 minute of the start date
        let startRange = startDate.addingTimeInterval(-30)
        let endRange = startDate.addingTimeInterval(30)

        let predicate = HKQuery.predicateForSamples(
            withStart: startRange,
            end: endRange,
            options: .strictStartDate
        )

        let workoutPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, workoutPredicate])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: compoundPredicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples?.count ?? 0) > 0)
                }
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Read Body Weight

    /// Fetch the latest body weight from HealthKit
    func fetchLatestBodyWeight() async throws -> (weight: Double, date: Date)? {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: (weightInKg, sample.startDate))
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case invalidSession

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "HealthKit access has not been authorized. Please enable it in Settings."
        case .invalidSession:
            return "The workout session is not valid for saving to HealthKit."
        }
    }
}
