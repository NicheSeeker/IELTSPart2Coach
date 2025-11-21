//
//  IELTSPart2CoachApp.swift
//  IELTSPart2Coach
//
//  Created by Charlie on 2025-11-04.
//

import SwiftUI
import UserNotifications
import Combine

@main
struct IELTSPart2CoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // ✅ FIX: Removed diagnostic logging to speed up startup
        // Performance Optimization (Phase 7.1.1):
        // - SwiftData disabled until non-blocking persistence solution is ready
        // - HapticManager: Auto-prepares on first use (no blocking)
        // - AudioSessionManager: Lazy initialization (configured when recording starts)
        // - SoundEffects: Lazy async initialization (generates on first play)
        // - AudioRecorder/AudioPlayer: Created by RecordingViewModel
        //
        // CRITICAL: No synchronous I/O operations here to avoid Watchdog timeout
        // iOS kills apps that block main thread >20s during launch (Signal 9)

        // Performance Optimization: Preload SF Rounded font
        // This eliminates first-render lag when expanding prompts
        preloadFonts()
    }

    /// Preload SF Rounded font to avoid first-render lag
    /// Fixes "前几次卡，后面好" issue on iPhone 16
    private func preloadFonts() {
        // Force CoreText to cache SF Rounded font
        _ = UIFont.systemFont(ofSize: 14, weight: .regular)
        if let descriptor = UIFont.systemFont(ofSize: 14, weight: .regular).fontDescriptor.withDesign(.rounded) {
            _ = UIFont(descriptor: descriptor, size: 14)
        }

        #if DEBUG
        print("🔤 SF Rounded font preloaded")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.deepLinkHandler)
                // Phase 5: Removed .preferredColorScheme - now follows system
                // Phase 7.4 Fix: Refresh notification permission status when app returns to foreground
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await NotificationManager.shared.updateSystemPermissionStatus()
                        // ✅ FIX: Only log in debug builds
                        #if DEBUG
                        // print("🔄 App returned to foreground, refreshed notification permission status")
                        #endif
                    }
                }
        }
    }
}

// MARK: - AppDelegate (Phase 7.4: Notification Handling)

class AppDelegate: NSObject, UIApplicationDelegate {
    let deepLinkHandler = DeepLinkHandler()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Handle notification tap (app in foreground)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract topicID from notification
        if let topicIDString = userInfo["topicID"] as? String,
           let topicID = UUID(uuidString: topicIDString) {
            // Trigger deep link
            deepLinkHandler.handleNotificationTap(topicID: topicID)

            #if DEBUG
            // print("📲 Notification tapped, loading topic: \(topicID)")
            #endif
        }

        completionHandler()
    }

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

// MARK: - DeepLinkHandler (Phase 7.4)

@MainActor
class DeepLinkHandler: ObservableObject {
    @Published var pendingTopicID: UUID?

    func handleNotificationTap(topicID: UUID) {
        pendingTopicID = topicID
    }

    func clearPendingDeepLink() {
        pendingTopicID = nil
    }
}
