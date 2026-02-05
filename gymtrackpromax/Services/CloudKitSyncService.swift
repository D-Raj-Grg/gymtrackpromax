//
//  CloudKitSyncService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 05/02/26.
//

import Foundation
import CloudKit

/// Represents the current state of CloudKit sync
enum CloudKitSyncStatus: Equatable {
    case idle
    case importing
    case exporting
    case error(String)

    var displayText: String {
        switch self {
        case .idle:
            return "Up to date"
        case .importing:
            return "Downloading..."
        case .exporting:
            return "Uploading..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var isActive: Bool {
        switch self {
        case .importing, .exporting:
            return true
        default:
            return false
        }
    }
}

/// Service for managing CloudKit sync state and status
@MainActor
final class CloudKitSyncService {
    // MARK: - Singleton

    static let shared = CloudKitSyncService()

    // MARK: - Properties

    /// CloudKit container identifier
    static let containerIdentifier = "iCloud.com.gymtrackpromax"

    /// Whether CloudKit sync is enabled by the user
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.cloudKitSyncEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.cloudKitSyncEnabled)
            NotificationCenter.default.post(name: .cloudKitSyncSettingChanged, object: nil)
        }
    }

    /// Last successful sync date
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: UserDefaultsKeys.cloudKitLastSyncDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.cloudKitLastSyncDate) }
    }

    /// Current sync status
    private(set) var syncStatus: CloudKitSyncStatus = .idle {
        didSet {
            if syncStatus != oldValue {
                NotificationCenter.default.post(name: .cloudKitSyncStatusChanged, object: nil)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Account Status

    /// Check the current iCloud account status
    func checkAccountStatus() async throws -> CKAccountStatus {
        let container = CKContainer(identifier: Self.containerIdentifier)
        return try await container.accountStatus()
    }

    /// Get a human-readable description of the account status
    func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "Signed In"
        case .noAccount:
            return "Not Signed In"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }

    /// Check if iCloud account is available
    func isAccountAvailable() async -> Bool {
        do {
            let status = try await checkAccountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    // MARK: - Sync Status Observation

    private func setupNotificationObservers() {
        // Observe CloudKit sync events from Core Data
        // NSPersistentCloudKitContainer posts these notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: nil
        )
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        Task { @MainActor in
            // Update last sync date when we receive sync events
            self.lastSyncDate = Date()
            self.syncStatus = .idle
        }
    }

    /// Manually update sync status (called when observing import/export events)
    func updateSyncStatus(_ status: CloudKitSyncStatus) {
        syncStatus = status

        if case .idle = status {
            lastSyncDate = Date()
        }
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    /// Posted when CloudKit sync status changes
    static let cloudKitSyncStatusChanged = Notification.Name("cloudKitSyncStatusChanged")

    /// Posted when CloudKit sync setting (enabled/disabled) changes
    static let cloudKitSyncSettingChanged = Notification.Name("cloudKitSyncSettingChanged")
}
