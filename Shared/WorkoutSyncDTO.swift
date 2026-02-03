//
//  WorkoutSyncDTO.swift
//  GymTrack Pro
//
//  Data Transfer Objects for syncing workout data between iPhone and Watch.
//

import Foundation

// MARK: - Today's Workout DTO

/// Lightweight representation of today's workout for the Watch
struct TodayWorkoutDTO: Codable {
    let workoutDayId: String
    let workoutName: String
    let muscleGroups: [String]
    let exerciseCount: Int
    let estimatedDuration: Int // minutes
    let hasInProgressSession: Bool
    let sessionId: String? // If there's an in-progress session

    init(
        workoutDayId: String,
        workoutName: String,
        muscleGroups: [String],
        exerciseCount: Int,
        estimatedDuration: Int,
        hasInProgressSession: Bool = false,
        sessionId: String? = nil
    ) {
        self.workoutDayId = workoutDayId
        self.workoutName = workoutName
        self.muscleGroups = muscleGroups
        self.exerciseCount = exerciseCount
        self.estimatedDuration = estimatedDuration
        self.hasInProgressSession = hasInProgressSession
        self.sessionId = sessionId
    }
}

/// Response when no workout is scheduled
struct RestDayDTO: Codable {
    let isRestDay: Bool
    let message: String

    init(message: String = "Rest Day") {
        self.isRestDay = true
        self.message = message
    }
}

// MARK: - Workout State DTO

/// Current state of an active workout session
struct WorkoutStateDTO: Codable {
    let sessionId: String
    let workoutName: String
    let startTime: Date
    let currentExerciseIndex: Int
    let exercises: [ExerciseStateDTO]
    let totalVolume: Double
    let totalSetsLogged: Int

    init(
        sessionId: String,
        workoutName: String,
        startTime: Date,
        currentExerciseIndex: Int,
        exercises: [ExerciseStateDTO],
        totalVolume: Double,
        totalSetsLogged: Int
    ) {
        self.sessionId = sessionId
        self.workoutName = workoutName
        self.startTime = startTime
        self.currentExerciseIndex = currentExerciseIndex
        self.exercises = exercises
        self.totalVolume = totalVolume
        self.totalSetsLogged = totalSetsLogged
    }
}

/// State of a single exercise in a workout
struct ExerciseStateDTO: Codable {
    let exerciseLogId: String
    let exerciseName: String
    let muscleGroup: String
    let targetSets: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let completedSets: [SetDTO]
    let suggestedWeight: Double
    let suggestedReps: Int
    let previousBest: String? // e.g., "60kg × 10"
    let isInSuperset: Bool
    let supersetPosition: Int? // 1-based position in superset

    init(
        exerciseLogId: String,
        exerciseName: String,
        muscleGroup: String,
        targetSets: Int,
        targetRepsMin: Int,
        targetRepsMax: Int,
        completedSets: [SetDTO],
        suggestedWeight: Double,
        suggestedReps: Int,
        previousBest: String? = nil,
        isInSuperset: Bool = false,
        supersetPosition: Int? = nil
    ) {
        self.exerciseLogId = exerciseLogId
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.completedSets = completedSets
        self.suggestedWeight = suggestedWeight
        self.suggestedReps = suggestedReps
        self.previousBest = previousBest
        self.isInSuperset = isInSuperset
        self.supersetPosition = supersetPosition
    }
}

/// A completed set
struct SetDTO: Codable {
    let setId: String
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isWarmup: Bool
    let isPR: Bool

    init(
        setId: String,
        setNumber: Int,
        weight: Double,
        reps: Int,
        isWarmup: Bool = false,
        isPR: Bool = false
    ) {
        self.setId = setId
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
        self.isPR = isPR
    }

    var display: String {
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.1f", weight)
        return "\(weightStr) × \(reps)"
    }
}

// MARK: - Log Set Request DTO

/// Request from Watch to log a set
struct LogSetRequestDTO: Codable {
    let exerciseLogId: String
    let weight: Double
    let reps: Int
    let isWarmup: Bool

    init(
        exerciseLogId: String,
        weight: Double,
        reps: Int,
        isWarmup: Bool = false
    ) {
        self.exerciseLogId = exerciseLogId
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
    }
}

/// Confirmation response after logging a set
struct SetLogConfirmationDTO: Codable {
    let success: Bool
    let setId: String?
    let isPR: Bool
    let prInfo: PRInfoDTO?
    let updatedState: WorkoutStateDTO?
    let errorMessage: String?

    init(
        success: Bool,
        setId: String? = nil,
        isPR: Bool = false,
        prInfo: PRInfoDTO? = nil,
        updatedState: WorkoutStateDTO? = nil,
        errorMessage: String? = nil
    ) {
        self.success = success
        self.setId = setId
        self.isPR = isPR
        self.prInfo = prInfo
        self.updatedState = updatedState
        self.errorMessage = errorMessage
    }
}

/// PR information
struct PRInfoDTO: Codable {
    let exerciseName: String
    let type: String // "Estimated 1RM", "Max Weight", etc.
    let value: Double
    let improvement: Double

    init(
        exerciseName: String,
        type: String,
        value: Double,
        improvement: Double
    ) {
        self.exerciseName = exerciseName
        self.type = type
        self.value = value
        self.improvement = improvement
    }
}

// MARK: - Workout Completion DTO

/// Summary sent when workout is completed
struct WorkoutCompletedDTO: Codable {
    let sessionId: String
    let duration: TimeInterval // seconds
    let totalVolume: Double
    let totalSets: Int
    let exercisesCompleted: Int
    let prsAchieved: Int

    init(
        sessionId: String,
        duration: TimeInterval,
        totalVolume: Double,
        totalSets: Int,
        exercisesCompleted: Int,
        prsAchieved: Int
    ) {
        self.sessionId = sessionId
        self.duration = duration
        self.totalVolume = totalVolume
        self.totalSets = totalSets
        self.exercisesCompleted = exercisesCompleted
        self.prsAchieved = prsAchieved
    }

    var durationDisplay: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Start Workout Request DTO

/// Request to start a workout
struct StartWorkoutRequestDTO: Codable {
    let workoutDayId: String

    init(workoutDayId: String) {
        self.workoutDayId = workoutDayId
    }
}

// MARK: - Encoding/Decoding Helpers

extension Encodable {
    /// Encode to dictionary for WatchConnectivity
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }

    /// Encode to Data
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }
}

extension Decodable {
    /// Decode from dictionary
    static func from(dictionary: [String: Any]) -> Self? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        return decoded
    }

    /// Decode from Data
    static func from(data: Data) -> Self? {
        try? JSONDecoder().decode(Self.self, from: data)
    }
}
