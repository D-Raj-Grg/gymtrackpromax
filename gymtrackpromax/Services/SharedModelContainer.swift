//
//  SharedModelContainer.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import Foundation
import SwiftData

/// Provides a shared SwiftData ModelContainer accessible by both the main app and widget extension.
/// Uses an App Group container so both targets can read/write the same database.
enum SharedModelContainer {

    // MARK: - Constants

    /// App Group identifier shared between the main app and widget extension.
    static let appGroupIdentifier = "group.gymtrackpromax.shared"

    /// Database file name.
    private static let storeName = "default.store"

    // MARK: - Schema

    /// The shared schema used by both the main app and widget extension.
    static let schema = Schema([
        User.self,
        WorkoutSplit.self,
        WorkoutDay.self,
        Exercise.self,
        PlannedExercise.self,
        WorkoutSession.self,
        ExerciseLog.self,
        SetLog.self
    ])

    // MARK: - Store URL

    /// URL for the SwiftData store inside the App Group container.
    static var sharedStoreURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("Unable to find App Group container: \(appGroupIdentifier)")
        }
        return containerURL.appendingPathComponent(storeName)
    }

    // MARK: - Container Creation

    /// Creates a read-write `ModelContainer` for the main app.
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: sharedStoreURL,
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates a read-only `ModelContainer` for the widget extension.
    static func makeReadOnlyContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: sharedStoreURL,
            allowsSave: false
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Migration

    /// Migrates the existing SwiftData store from the default location to the App Group container.
    /// Call this once on app launch before creating the shared container.
    /// - Returns: `true` if migration was performed, `false` if already migrated or no existing store.
    @discardableResult
    static func migrateStoreIfNeeded() -> Bool {
        let fileManager = FileManager.default

        // Check if the shared store already exists — skip migration
        if fileManager.fileExists(atPath: sharedStoreURL.path) {
            return false
        }

        // Locate the default SwiftData store
        guard let defaultStoreURL = defaultStoreURL() else {
            return false
        }

        // Check if a default store actually exists to migrate
        guard fileManager.fileExists(atPath: defaultStoreURL.path) else {
            return false
        }

        // Copy all SQLite related files (.store, .store-shm, .store-wal)
        let extensions = ["", "-shm", "-wal"]
        for ext in extensions {
            let source: URL
            if ext.isEmpty {
                source = defaultStoreURL
            } else {
                source = URL(fileURLWithPath: defaultStoreURL.path + ext)
            }

            let destination = URL(fileURLWithPath: sharedStoreURL.path + ext)

            if fileManager.fileExists(atPath: source.path) {
                do {
                    try fileManager.copyItem(at: source, to: destination)
                } catch {
                    // If any file fails to copy, clean up and return false
                    cleanUpPartialMigration()
                    return false
                }
            }
        }

        return true
    }

    // MARK: - Private Helpers

    /// Returns the default SwiftData store URL (before App Group migration).
    private static func defaultStoreURL() -> URL? {
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return appSupportURL.appendingPathComponent("default.store")
    }

    /// Removes partially migrated files if migration fails.
    private static func cleanUpPartialMigration() {
        let fileManager = FileManager.default
        let extensions = ["", "-shm", "-wal"]
        for ext in extensions {
            let path = sharedStoreURL.path + ext
            try? fileManager.removeItem(atPath: path)
        }
    }
}
