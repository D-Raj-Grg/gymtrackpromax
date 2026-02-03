//
//  WatchConnectivityService.swift
//  GymTrackProWatch
//
//  Watch-side WatchConnectivity service for communicating with iPhone.
//

import Combine
import Foundation
import WatchConnectivity

/// Service for handling connectivity with the paired iPhone
final class WatchConnectivityService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = WatchConnectivityService()

    // MARK: - Published State

    @Published var isPhoneReachable: Bool = false
    @Published var isActivated: Bool = false

    // MARK: - Callbacks

    var onTodayWorkoutReceived: ((TodayWorkoutDTO) -> Void)?
    var onRestDayReceived: ((RestDayDTO) -> Void)?
    var onWorkoutStateReceived: ((WorkoutStateDTO) -> Void)?
    var onSetLogConfirmationReceived: ((SetLogConfirmationDTO) -> Void)?
    var onWorkoutCompletedReceived: ((WorkoutCompletedDTO) -> Void)?
    var onErrorReceived: ((String) -> Void)?

    // MARK: - Private Properties

    private var session: WCSession?
    private var pendingMessages: [[String: Any]] = []

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Activate the WCSession
    func activate() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] WCSession not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("[WatchConnectivity] Activation requested")
    }

    // MARK: - Send Messages to iPhone

    /// Request today's workout from iPhone
    func requestTodayWorkout() {
        sendMessage(type: .requestTodayWorkout) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Request to start a workout
    func startWorkout(workoutDayId: String) {
        let request = StartWorkoutRequestDTO(workoutDayId: workoutDayId)

        guard let payload = request.toData() else {
            onErrorReceived?(WatchConnectivityError.encodingFailed.localizedDescription)
            return
        }

        sendMessage(type: .startWorkout, payload: payload) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Log a set
    func logSet(exerciseLogId: String, weight: Double, reps: Int, isWarmup: Bool) {
        let request = LogSetRequestDTO(
            exerciseLogId: exerciseLogId,
            weight: weight,
            reps: reps,
            isWarmup: isWarmup
        )

        guard let payload = request.toData() else {
            onErrorReceived?(WatchConnectivityError.encodingFailed.localizedDescription)
            return
        }

        sendMessage(type: .logSet, payload: payload) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Request current workout state
    func requestWorkoutState() {
        sendMessage(type: .requestWorkoutState) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Complete the current workout
    func completeWorkout() {
        sendMessage(type: .completeWorkout) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Navigate to next exercise
    func nextExercise() {
        sendMessage(type: .nextExercise) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    /// Navigate to previous exercise
    func previousExercise() {
        sendMessage(type: .previousExercise) { [weak self] response in
            self?.handleResponse(response)
        }
    }

    // MARK: - Private Methods

    private func sendMessage(
        type: WatchMessageType,
        payload: Data? = nil,
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let session = session else {
            print("[WatchConnectivity] Session not available")
            onErrorReceived?("Watch session not available")
            return
        }

        guard session.isReachable else {
            print("[WatchConnectivity] iPhone not reachable")
            onErrorReceived?(WatchConnectivityError.sessionNotReachable.localizedDescription)
            return
        }

        var message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: type.rawValue
        ]

        if let payload = payload {
            message[WatchMessageKey.payload.rawValue] = payload
        }

        session.sendMessage(message, replyHandler: replyHandler) { [weak self] error in
            print("[WatchConnectivity] Send failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.onErrorReceived?(error.localizedDescription)
            }
        }
    }

    private func handleResponse(_ response: [String: Any]) {
        guard let typeString = response[WatchMessageKey.messageType.rawValue] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            print("[WatchConnectivity] Invalid response type")
            return
        }

        print("[WatchConnectivity] Received response: \(messageType)")

        DispatchQueue.main.async { [weak self] in
            switch messageType {
            case .todayWorkout:
                self?.handleTodayWorkoutResponse(response)

            case .workoutState:
                self?.handleWorkoutStateResponse(response)

            case .setLogConfirmation:
                self?.handleSetLogConfirmationResponse(response)

            case .workoutCompleted:
                self?.handleWorkoutCompletedResponse(response)

            case .error:
                self?.handleErrorResponse(response)

            default:
                print("[WatchConnectivity] Unhandled response type: \(messageType)")
            }
        }
    }

    private func handleTodayWorkoutResponse(_ response: [String: Any]) {
        guard let payloadData = response[WatchMessageKey.payload.rawValue] as? Data else {
            onErrorReceived?("Invalid today workout response")
            return
        }

        // Try to decode as TodayWorkoutDTO first
        if let dto = TodayWorkoutDTO.from(data: payloadData) {
            onTodayWorkoutReceived?(dto)
            return
        }

        // Try RestDayDTO
        if let dto = RestDayDTO.from(data: payloadData) {
            onRestDayReceived?(dto)
            return
        }

        onErrorReceived?("Failed to decode today workout response")
    }

    private func handleWorkoutStateResponse(_ response: [String: Any]) {
        guard let payloadData = response[WatchMessageKey.payload.rawValue] as? Data,
              let dto = WorkoutStateDTO.from(data: payloadData) else {
            onErrorReceived?("Invalid workout state response")
            return
        }

        onWorkoutStateReceived?(dto)
    }

    private func handleSetLogConfirmationResponse(_ response: [String: Any]) {
        guard let payloadData = response[WatchMessageKey.payload.rawValue] as? Data,
              let dto = SetLogConfirmationDTO.from(data: payloadData) else {
            onErrorReceived?("Invalid set log confirmation response")
            return
        }

        onSetLogConfirmationReceived?(dto)
    }

    private func handleWorkoutCompletedResponse(_ response: [String: Any]) {
        guard let payloadData = response[WatchMessageKey.payload.rawValue] as? Data,
              let dto = WorkoutCompletedDTO.from(data: payloadData) else {
            onErrorReceived?("Invalid workout completed response")
            return
        }

        onWorkoutCompletedReceived?(dto)
    }

    private func handleErrorResponse(_ response: [String: Any]) {
        let errorMessage = response[WatchMessageKey.errorMessage.rawValue] as? String ?? "Unknown error"
        onErrorReceived?(errorMessage)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("[WatchConnectivity] Activation failed: \(error.localizedDescription)")
                self?.onErrorReceived?(error.localizedDescription)
                return
            }

            let stateString: String
            switch activationState {
            case .notActivated: stateString = "notActivated"
            case .inactive: stateString = "inactive"
            case .activated: stateString = "activated"
            @unknown default: stateString = "unknown(\(activationState.rawValue))"
            }

            print("[WatchConnectivity] ===== WCSession Status =====")
            print("[WatchConnectivity] Activation state: \(stateString)")
            print("[WatchConnectivity] isReachable: \(session.isReachable)")
            print("[WatchConnectivity] isCompanionAppInstalled: \(session.isCompanionAppInstalled)")
            print("[WatchConnectivity] ============================")

            // NOTE: In simulator, connectivity between Watch and iPhone can be unreliable
            // due to known Xcode bugs. Real device testing is recommended.
            if !session.isReachable {
                print("[WatchConnectivity] ⚠️ iPhone not reachable - this may be a simulator limitation")
                print("[WatchConnectivity] ⚠️ Try running iPhone and Watch apps on separate simulators")
            }

            self?.isActivated = activationState == .activated
            self?.isPhoneReachable = session.isReachable

            // Check for any pending application context
            let context = session.receivedApplicationContext
            if !context.isEmpty {
                print("[WatchConnectivity] Found pending application context")
                self?.handleResponse(context)
            }

            // Request today's workout on activation
            if session.isReachable {
                self?.requestTodayWorkout()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WatchConnectivity] Received application context")
        DispatchQueue.main.async { [weak self] in
            self?.handleResponse(applicationContext)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isPhoneReachable = session.isReachable
            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")

            // Request today's workout when phone becomes reachable
            if session.isReachable {
                self?.requestTodayWorkout()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle push messages from iPhone
        handleResponse(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Handle messages that expect a reply
        handleResponse(message)

        // Send acknowledgment
        replyHandler([
            WatchMessageKey.messageType.rawValue: "ack"
        ])
    }
}
