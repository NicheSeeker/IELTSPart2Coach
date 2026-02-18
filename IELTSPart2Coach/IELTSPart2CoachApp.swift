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
                // Phase 5: Removed .preferredColorScheme - now follows system
                // Phase 7.4 Fix: Refresh notification permission status when app returns to foreground
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await NotificationManager.shared.updateSystemPermissionStatus()
                        // ✅ FIX: Only log in debug builds
                    }
                }
                // Phase 7.1.2: Memory warning handler to prevent crashes
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    #if DEBUG
                    print("⚠️ Memory warning received, triggering cleanup")
                    #endif

                    // Notify managers to release unnecessary resources
                    Task { @MainActor in
                        // DataManager will trim old sessions if over limit (already implemented)
                        // AudioRecorder clears fullWaveform after downsampling (already implemented)
                        // Future: Add explicit cleanup methods if needed
                    }
                }
        }
    }
}

// MARK: - AppDelegate (Phase 7.4: Notification Handling)

class AppDelegate: NSObject, UIApplicationDelegate {
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
        // Notification tap just opens the app (no deep link to specific topic)
        #if DEBUG
        let userInfo = response.notification.request.content.userInfo
        print("📲 Notification tapped: \(userInfo["topicTitle"] as? String ?? "unknown")")
        #endif

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
