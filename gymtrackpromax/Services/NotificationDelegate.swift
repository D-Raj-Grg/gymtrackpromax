//
//  NotificationDelegate.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import Foundation
import UserNotifications

/// Handles notification center delegate callbacks
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Handle notification tap when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        if identifier.contains("rest-timer") {
            // Post notification to switch to workout tab
            NotificationCenter.default.post(name: .restTimerNotificationTapped, object: nil)
        }

        completionHandler()
    }
}
