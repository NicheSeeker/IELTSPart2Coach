//
//  NotificationManager.swift
//  IELTSPart2Coach
//
//  Phase 7.4: Local notification system for 3-day practice reminders
//  Handles permission requests, notification scheduling, and user preferences
//

import Foundation
import UserNotifications

@MainActor
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    // MARK: - Observable State

    /// Whether 3-day reminders are enabled (Toggle state in Settings)
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")

            // If disabled, cancel all pending notifications
            if !newValue {
                cancelAllNotifications()
            }
        }
    }

    /// System-level notification permission status
    var systemPermissionStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Private State

    /// Track if pre-prompt was shown (to avoid showing multiple times)
    private var hasShownPrePrompt: Bool {
        get { UserDefaults.standard.bool(forKey: "hasShownNotificationPrePrompt") }
        set { UserDefaults.standard.set(newValue, forKey: "hasShownNotificationPrePrompt") }
    }

    /// Track if user explicitly denied pre-prompt (show again next time)
    private var userDeniedPrePrompt: Bool {
        get { UserDefaults.standard.bool(forKey: "userDeniedNotificationPrePrompt") }
        set { UserDefaults.standard.set(newValue, forKey: "userDeniedNotificationPrePrompt") }
    }

    private let center = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {
        // TEMPORARY DIAGNOSTIC: Disabled to test if this is causing first-launch freeze
        // Load initial system permission status
        // Task {
        //     await updateSystemPermissionStatus()
        // }

        #if DEBUG
        print("🔔 NotificationManager.init() started (diagnostic mode - no permission check)")
        #endif
    }

    // MARK: - Permission Management

    /// Check if we should show pre-prompt (called after AI feedback success)
    func shouldShowPrePrompt() -> Bool {
        #if DEBUG
        print("📊 NotificationManager state:")
        print("   hasShownPrePrompt: \(hasShownPrePrompt)")
        print("   userDeniedPrePrompt: \(userDeniedPrePrompt)")
        print("   systemPermissionStatus: \(systemPermissionStatus.rawValue) (\(systemPermissionStatus.debugDescription))")
        #endif

        // CRITICAL: If system permission is already denied, don't show pre-prompt
        // User must go to Settings to re-enable
        if systemPermissionStatus == .denied {
            #if DEBUG
            print("   ⚠️ System permission denied, skipping pre-prompt")
            print("   → shouldShowPrePrompt: false")
            #endif
            return false
        }

        // CRITICAL: If system permission is already authorized, don't show pre-prompt
        // Just schedule notification directly
        if systemPermissionStatus == .authorized {
            #if DEBUG
            print("   ✅ System permission already granted, skipping pre-prompt")
            print("   → shouldShowPrePrompt: false")
            #endif
            return false
        }

        // Show pre-prompt if:
        // 1. Never shown before, OR
        // 2. User denied pre-prompt last time (give one more chance)
        let shouldShow = !hasShownPrePrompt || userDeniedPrePrompt

        #if DEBUG
        print("   → shouldShowPrePrompt: \(shouldShow)")
        #endif

        return shouldShow
    }

    /// User agreed to pre-prompt → Request system permission
    func handlePrePromptAccepted() async {
        hasShownPrePrompt = true
        userDeniedPrePrompt = false

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            await updateSystemPermissionStatus()

            if granted {
                // Auto-enable toggle
                isEnabled = true

                #if DEBUG
                print("✅ Notification permission granted, toggle enabled")
                #endif
            } else {
                #if DEBUG
                print("⚠️ Notification permission denied by user")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ Failed to request notification permission: \(error)")
            #endif
        }
    }

    /// User declined pre-prompt → Mark for retry next time
    func handlePrePromptDenied() {
        hasShownPrePrompt = true
        userDeniedPrePrompt = true

        #if DEBUG
        print("ℹ️ User denied pre-prompt, will show again next time")
        #endif
    }

    /// Update system permission status (call on app launch and after requests)
    func updateSystemPermissionStatus() async {
        let settings = await center.notificationSettings()
        systemPermissionStatus = settings.authorizationStatus

        #if DEBUG
        print("🔔 System notification status: \(settings.authorizationStatus.rawValue)")
        #endif
    }

    // MARK: - Notification Scheduling

    /// Schedule a 3-day reminder for a practice session
    func scheduleReminder(
        sessionID: UUID,
        topicTitle: String,
        topicID: UUID
    ) async {
        // Only schedule if toggle is enabled
        guard isEnabled else {
            #if DEBUG
            print("ℹ️ Notifications disabled, skipping schedule")
            #endif
            return
        }

        // Check system permission
        await updateSystemPermissionStatus()
        guard systemPermissionStatus == .authorized else {
            #if DEBUG
            print("⚠️ No notification permission, skipping schedule")
            #endif
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to practice again!"
        content.body = "Try: \(topicTitle)"
        content.sound = .default

        // Add topic ID to userInfo for deep link
        content.userInfo = [
            "sessionID": sessionID.uuidString,
            "topicID": topicID.uuidString,
            "topicTitle": topicTitle
        ]

        // Trigger: 3 days from now
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3 * 24 * 60 * 60,  // 3 days in seconds
            repeats: false
        )

        // Create request (use sessionID as identifier)
        let request = UNNotificationRequest(
            identifier: sessionID.uuidString,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await center.add(request)

            #if DEBUG
            print("✅ Scheduled notification for session \(sessionID)")
            print("   Topic: \(topicTitle)")
            print("   Trigger: 3 days from now")
            #endif
        } catch {
            // Silent failure (as per requirement)
            #if DEBUG
            print("❌ Failed to schedule notification: \(error)")
            #endif
        }
    }

    /// Cancel all pending notifications (when toggle is disabled)
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()

        #if DEBUG
        print("🗑 Cancelled all pending notifications")
        #endif
    }

    /// Cancel a specific notification by session ID
    func cancelNotification(sessionID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [sessionID.uuidString])

        #if DEBUG
        print("🗑 Cancelled notification for session \(sessionID)")
        #endif
    }
}

// MARK: - UNAuthorizationStatus Extension

extension UNAuthorizationStatus {
    /// Human-readable description for debugging
    var debugDescription: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}
