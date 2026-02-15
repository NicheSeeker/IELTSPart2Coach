//
//  AppReviewManager.swift
//  IELTSPart2Coach
//
//  Request App Store review at milestone practice sessions
//

import StoreKit
import UIKit

@MainActor
class AppReviewManager {
    static let shared = AppReviewManager()

    private let milestones: Set<Int> = [3, 10, 30]

    private init() {}

    /// Request review after completing milestone practice sessions
    /// StoreKit shows prompt max 3 times per year per user
    func requestReviewIfAppropriate() {
        let sessionCount = (try? DataManager.shared.fetchAllSessions().count) ?? 0

        guard milestones.contains(sessionCount) else { return }

        #if DEBUG
        print("⭐ Review prompt requested (session #\(sessionCount))")
        #endif

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
        }
    }
}
