//
//  PhoneConnectivityService.swift
//  GymTrack Pro
//
//  iPhone-side WatchConnectivity service for communicating with Apple Watch.
//

import Combine
import Foundation
import SwiftData
import WatchConnectivity

/// Service for handling Watch connectivity on the iPhone side
@MainActor
final class PhoneConnectivityService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = PhoneConnectivityService()

    // MARK: - Published State

    @Published var isWatchReachable: Bool = false
    @Published var isWatchPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false

    // MARK: - Private Properties

    private var session: WCSession?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Activate the WCSession and set the model context
    func activate(modelContext: ModelContext) {
        self.modelContext = modelContext

        guard WCSession.isSupported() else {
            print("[PhoneConnectivity] WCSession not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("[PhoneConnectivity] WCSession activation requested")
    }

    // MARK: - Send Messages to Watch

    /// Send today's workout to Watch
    func sendTodayWorkout() {
        guard let context = modelContext else { return }

        Task { @MainActor in
            let result = buildTodayWorkoutDTO(context: context)
            if let workout = result as? TodayWorkoutDTO {
                sendMessage(type: .todayWorkout, payload: workout)
            } else if let restDay = result as? RestDayDTO {
                sendMessage(type: .restDay, payload: restDay)
            }
        }
    }

    /// Send current workout state to Watch
    func sendWorkoutState() {
        guard let context = modelContext else { return }

        Task { @MainActor in
            if let dto = buildWorkoutStateDTO(context: context) {
                sendMessage(type: .workoutState, payload: dto)
            } else {
                sendError(.noActiveSession)
            }
        }
    }

    /// Send workout completed notification to Watch
    func sendWorkoutCompleted(_ dto: WorkoutCompletedDTO) {
        sendMessage(type: .workoutCompleted, payload: dto)
    }

    /// Send set log confirmation to Watch
    func sendSetLogConfirmation(_ dto: SetLogConfirmationDTO) {
        sendMessage(type: .setLogConfirmation, payload: dto)
    }

    // MARK: - Private Message Handling

    private func sendMessage<T: Encodable>(type: WatchMessageType, payload: T) {
        guard let session = session else {
            print("[PhoneConnectivity] Session not available")
            return
        }

        guard session.activationState == .activated else {
            print("[PhoneConnectivity] Session not activated yet")
            return
        }

        guard let payloadData = payload.toData() else {
            print("[PhoneConnectivity] Failed to encode payload")
            return
        }

        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: type.rawValue,
            WatchMessageKey.payload.rawValue: payloadData
        ]

        // If reachable, send immediately
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("[PhoneConnectivity] Failed to send message: \(error.localizedDescription)")
            }
        } else {
            // Use application context as fallback for when Watch app opens
            // NOTE: In simulator, isWatchAppInstalled returns false even when app is installed
            // (known Xcode bug). We still try updateApplicationContext - it may fail in simulator
            // but works on real devices.
            print("[PhoneConnectivity] Watch not reachable, using application context")
            do {
                try session.updateApplicationContext(message)
            } catch {
                // WCErrorCodeWatchAppNotInstalled (7007) is expected in simulator due to bug
                let nsError = error as NSError
                if nsError.domain == "WCErrorDomain" && nsError.code == 7007 {
                    print("[PhoneConnectivity] ⚠️ updateApplicationContext failed (simulator bug) - this works on real devices")
                } else {
                    print("[PhoneConnectivity] Failed to update application context: \(error.localizedDescription)")
                }
            }
        }
    }

    private func sendError(_ error: WatchConnectivityError) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.error.rawValue,
            WatchMessageKey.errorMessage.rawValue: error.rawValue
        ]

        session.sendMessage(message, replyHandler: nil) { sendError in
            print("[PhoneConnectivity] Failed to send error: \(sendError.localizedDescription)")
        }
    }

    // MARK: - DTO Builders

    private func buildTodayWorkoutDTO(context: ModelContext) -> Any {
        // Fetch active user
        guard let user = fetchActiveUser(context: context),
              let activeSplit = user.activeSplit,
              let todayWorkout = activeSplit.todaysWorkout else {
            return RestDayDTO()
        }

        let muscleGroups = todayWorkout.primaryMuscles.map { $0.displayName }
        let hasInProgress = todayWorkout.inProgressSession != nil

        return TodayWorkoutDTO(
            workoutDayId: todayWorkout.id.uuidString,
            workoutName: todayWorkout.name,
            muscleGroups: muscleGroups,
            exerciseCount: todayWorkout.exerciseCount,
            estimatedDuration: todayWorkout.estimatedDuration,
            hasInProgressSession: hasInProgress,
            sessionId: todayWorkout.inProgressSession?.id.uuidString
        )
    }

    func buildWorkoutStateDTO(context: ModelContext) -> WorkoutStateDTO? {
        guard let user = fetchActiveUser(context: context),
              let session = findActiveSession(user: user) else {
            return nil
        }

        let exercises = session.sortedExerciseLogs.enumerated().map { index, log -> ExerciseStateDTO in
            let completedSets = log.sortedSets.map { set in
                SetDTO(
                    setId: set.id.uuidString,
                    setNumber: set.setNumber,
                    weight: set.weight,
                    reps: set.reps,
                    isWarmup: set.isWarmup,
                    isPR: false // TODO: Track PRs
                )
            }

            // Get planned exercise info
            let workoutDay = session.workoutDay
            let plannedExercise = workoutDay?.sortedExercises.first { $0.exercise?.id == log.exercise?.id }

            // Calculate suggested weight
            var suggestedWeight: Double = 0
            if let exercise = log.exercise {
                suggestedWeight = WorkoutService.shared.suggestWeight(
                    for: exercise,
                    user: user,
                    context: context
                ) ?? 0
            }

            // Get previous best
            var previousBest: String?
            if let exercise = log.exercise, let workoutDay = workoutDay {
                previousBest = WorkoutService.shared.getPreviousSetsDisplay(
                    exercise: exercise,
                    workoutDay: workoutDay,
                    context: context
                )
            }

            return ExerciseStateDTO(
                exerciseLogId: log.id.uuidString,
                exerciseName: log.exerciseName,
                muscleGroup: log.exercise?.primaryMuscle.displayName ?? "Unknown",
                targetSets: plannedExercise?.targetSets ?? 3,
                targetRepsMin: plannedExercise?.targetRepsMin ?? 8,
                targetRepsMax: plannedExercise?.targetRepsMax ?? 12,
                completedSets: completedSets,
                suggestedWeight: suggestedWeight,
                suggestedReps: (plannedExercise?.targetRepsMin ?? 8 + (plannedExercise?.targetRepsMax ?? 12)) / 2,
                previousBest: previousBest,
                isInSuperset: log.isInSuperset,
                supersetPosition: log.isInSuperset ? log.supersetOrder + 1 : nil
            )
        }

        return WorkoutStateDTO(
            sessionId: session.id.uuidString,
            workoutName: session.workoutDay?.name ?? "Workout",
            startTime: session.startTime,
            currentExerciseIndex: 0, // Watch maintains its own index
            exercises: exercises,
            totalVolume: session.totalVolume,
            totalSetsLogged: session.totalSets
        )
    }

    // MARK: - Message Handlers

    private func handleRequestTodayWorkout(replyHandler: @escaping ([String: Any]) -> Void) {
        guard let context = modelContext else {
            replyWithError(.noActiveUser, replyHandler: replyHandler)
            return
        }

        let dto = buildTodayWorkoutDTO(context: context)

        if let todayDTO = dto as? TodayWorkoutDTO, let payloadData = todayDTO.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.todayWorkout.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])
        } else if let restDTO = dto as? RestDayDTO, let payloadData = restDTO.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.todayWorkout.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])
        }
    }

    private func handleStartWorkout(payload: Data, replyHandler: @escaping ([String: Any]) -> Void) {
        guard let context = modelContext else {
            replyWithError(.noActiveUser, replyHandler: replyHandler)
            return
        }

        guard let request = StartWorkoutRequestDTO.from(data: payload) else {
            replyWithError(.invalidPayload, replyHandler: replyHandler)
            return
        }

        guard let workoutDayId = UUID(uuidString: request.workoutDayId),
              let user = fetchActiveUser(context: context) else {
            replyWithError(.noActiveUser, replyHandler: replyHandler)
            return
        }

        // Find the workout day
        guard let workoutDay = findWorkoutDay(id: workoutDayId, context: context) else {
            replyWithError(.noWorkoutToday, replyHandler: replyHandler)
            return
        }

        // Check if there's already an active session
        if findActiveSession(user: user) != nil {
            replyWithError(.workoutAlreadyInProgress, replyHandler: replyHandler)
            return
        }

        // Start the workout
        let session = WorkoutService.shared.startWorkout(
            workoutDay: workoutDay,
            user: user,
            context: context
        )

        // Build and send state
        if let stateDTO = buildWorkoutStateDTO(context: context), let payloadData = stateDTO.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.workoutState.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])

            // Post notification so iPhone UI updates
            NotificationCenter.default.post(
                name: .workoutStartedFromWatch,
                object: session
            )
        } else {
            replyWithError(.encodingFailed, replyHandler: replyHandler)
        }
    }

    private func handleLogSet(payload: Data, replyHandler: @escaping ([String: Any]) -> Void) {
        guard let context = modelContext else {
            replyWithError(.noActiveUser, replyHandler: replyHandler)
            return
        }

        guard let request = LogSetRequestDTO.from(data: payload) else {
            replyWithError(.invalidPayload, replyHandler: replyHandler)
            return
        }

        guard let exerciseLogId = UUID(uuidString: request.exerciseLogId) else {
            replyWithError(.exerciseNotFound, replyHandler: replyHandler)
            return
        }

        guard let user = fetchActiveUser(context: context),
              let session = findActiveSession(user: user),
              let exerciseLog = session.exerciseLogs.first(where: { $0.id == exerciseLogId }) else {
            replyWithError(.noActiveSession, replyHandler: replyHandler)
            return
        }

        // Log the set
        let setLog = WorkoutService.shared.logSet(
            exerciseLog: exerciseLog,
            weight: request.weight,
            reps: request.reps,
            duration: nil,
            rpe: nil,
            isWarmup: request.isWarmup,
            isDropset: false,
            context: context
        )

        // Check for PR
        var prInfo: PRInfoDTO?
        var isPR = false

        if let exercise = exerciseLog.exercise {
            if let pr = WorkoutService.shared.checkForPR(
                exercise: exercise,
                newSet: setLog,
                user: user,
                context: context
            ) {
                isPR = true
                prInfo = PRInfoDTO(
                    exerciseName: pr.exerciseName,
                    type: pr.type.displayName,
                    value: pr.value,
                    improvement: pr.improvement
                )
            }
        }

        // Build updated state
        let updatedState = buildWorkoutStateDTO(context: context)

        let confirmation = SetLogConfirmationDTO(
            success: true,
            setId: setLog.id.uuidString,
            isPR: isPR,
            prInfo: prInfo,
            updatedState: updatedState
        )

        if let payloadData = confirmation.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.setLogConfirmation.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])

            // Post notification so iPhone UI updates
            NotificationCenter.default.post(
                name: .setLoggedFromWatch,
                object: setLog
            )
        } else {
            replyWithError(.encodingFailed, replyHandler: replyHandler)
        }
    }

    private func handleRequestWorkoutState(replyHandler: @escaping ([String: Any]) -> Void) {
        guard let context = modelContext else {
            replyWithError(.noActiveUser, replyHandler: replyHandler)
            return
        }

        if let stateDTO = buildWorkoutStateDTO(context: context), let payloadData = stateDTO.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.workoutState.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])
        } else {
            replyWithError(.noActiveSession, replyHandler: replyHandler)
        }
    }

    private func handleCompleteWorkout(replyHandler: @escaping ([String: Any]) -> Void) {
        guard let context = modelContext,
              let user = fetchActiveUser(context: context),
              let session = findActiveSession(user: user) else {
            replyWithError(.noActiveSession, replyHandler: replyHandler)
            return
        }

        // Complete the workout
        WorkoutService.shared.endWorkout(
            session: session,
            notes: nil,
            context: context
        )

        let completedDTO = WorkoutCompletedDTO(
            sessionId: session.id.uuidString,
            duration: session.duration ?? 0,
            totalVolume: session.totalVolume,
            totalSets: session.totalSets,
            exercisesCompleted: session.exerciseLogs.filter { !$0.sets.isEmpty }.count,
            prsAchieved: 0 // TODO: Track PRs count
        )

        if let payloadData = completedDTO.toData() {
            replyHandler([
                WatchMessageKey.messageType.rawValue: WatchMessageType.workoutCompleted.rawValue,
                WatchMessageKey.payload.rawValue: payloadData
            ])

            // Post notification so iPhone UI updates
            NotificationCenter.default.post(
                name: .workoutCompletedFromWatch,
                object: session
            )
        } else {
            replyWithError(.encodingFailed, replyHandler: replyHandler)
        }
    }

    private func replyWithError(_ error: WatchConnectivityError, replyHandler: @escaping ([String: Any]) -> Void) {
        replyHandler([
            WatchMessageKey.messageType.rawValue: WatchMessageType.error.rawValue,
            WatchMessageKey.errorMessage.rawValue: error.rawValue
        ])
    }

    // MARK: - Data Helpers

    private func fetchActiveUser(context: ModelContext) -> User? {
        let descriptor = FetchDescriptor<User>()
        return try? context.fetch(descriptor).first
    }

    private func findActiveSession(user: User) -> WorkoutSession? {
        // Find session that's started but not completed
        user.workoutSessions.first { $0.endTime == nil }
    }

    private func findWorkoutDay(id: UUID, context: ModelContext) -> WorkoutDay? {
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                print("[PhoneConnectivity] Activation failed: \(error.localizedDescription)")
                return
            }

            let stateString: String
            switch activationState {
            case .notActivated: stateString = "notActivated"
            case .inactive: stateString = "inactive"
            case .activated: stateString = "activated"
            @unknown default: stateString = "unknown(\(activationState.rawValue))"
            }

            print("[PhoneConnectivity] ===== WCSession Status =====")
            print("[PhoneConnectivity] Activation state: \(stateString)")
            print("[PhoneConnectivity] isPaired: \(session.isPaired)")
            print("[PhoneConnectivity] isWatchAppInstalled: \(session.isWatchAppInstalled)")
            print("[PhoneConnectivity] isReachable: \(session.isReachable)")
            print("[PhoneConnectivity] isComplicationEnabled: \(session.isComplicationEnabled)")
            #if !targetEnvironment(simulator)
            print("[PhoneConnectivity] watchDirectoryURL: \(session.watchDirectoryURL?.absoluteString ?? "nil")")
            #endif
            print("[PhoneConnectivity] ============================")

            // NOTE: In simulator, isWatchAppInstalled often returns false due to known Xcode bug
            // See: https://developer.apple.com/forums/thread/695643
            // Real device testing is recommended for WatchConnectivity
            if !session.isWatchAppInstalled {
                print("[PhoneConnectivity] ⚠️ Watch app shows not installed - this is a known simulator bug")
                print("[PhoneConnectivity] ⚠️ WatchConnectivity works best on real devices")
            }

            isWatchPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("[PhoneConnectivity] Session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("[PhoneConnectivity] Session deactivated")
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            print("[PhoneConnectivity] Reachability changed: \(session.isReachable)")

            // Send today's workout when Watch becomes reachable
            if session.isReachable {
                sendTodayWorkout()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            handleMessage(message, replyHandler: replyHandler)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            handleMessage(message, replyHandler: nil)
        }
    }

    @MainActor
    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let typeString = message[WatchMessageKey.messageType.rawValue] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            print("[PhoneConnectivity] Invalid message type")
            replyHandler?([
                WatchMessageKey.messageType.rawValue: WatchMessageType.error.rawValue,
                WatchMessageKey.errorMessage.rawValue: WatchConnectivityError.invalidPayload.rawValue
            ])
            return
        }

        print("[PhoneConnectivity] Received message: \(messageType)")

        let payload = message[WatchMessageKey.payload.rawValue] as? Data

        guard let replyHandler = replyHandler else {
            // Fire-and-forget message, just log it
            print("[PhoneConnectivity] No reply handler for message type: \(messageType)")
            return
        }

        switch messageType {
        case .requestTodayWorkout:
            handleRequestTodayWorkout(replyHandler: replyHandler)

        case .startWorkout:
            guard let payload = payload else {
                replyWithError(.invalidPayload, replyHandler: replyHandler)
                return
            }
            handleStartWorkout(payload: payload, replyHandler: replyHandler)

        case .logSet:
            guard let payload = payload else {
                replyWithError(.invalidPayload, replyHandler: replyHandler)
                return
            }
            handleLogSet(payload: payload, replyHandler: replyHandler)

        case .requestWorkoutState:
            handleRequestWorkoutState(replyHandler: replyHandler)

        case .completeWorkout:
            handleCompleteWorkout(replyHandler: replyHandler)

        case .nextExercise, .previousExercise:
            // These are handled on Watch side, just send updated state
            handleRequestWorkoutState(replyHandler: replyHandler)

        default:
            print("[PhoneConnectivity] Unhandled message type: \(messageType)")
            replyWithError(.invalidPayload, replyHandler: replyHandler)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a workout is started from Watch
    static let workoutStartedFromWatch = Notification.Name("workoutStartedFromWatch")

    /// Posted when a set is logged from Watch
    static let setLoggedFromWatch = Notification.Name("setLoggedFromWatch")

    /// Posted when a workout is completed from Watch
    static let workoutCompletedFromWatch = Notification.Name("workoutCompletedFromWatch")
}
