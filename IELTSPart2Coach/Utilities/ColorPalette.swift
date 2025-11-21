//
//  ColorPalette.swift
//  IELTSPart2Coach
//
//  Liquid Glass Design System
//  Color palette following iOS 26 Liquid Glass visual language
//  Phase 5: Added Dark Mode support
//

import SwiftUI

extension Color {
    // MARK: - Light Mode Colors

    /// Fog White - Primary Background (#F8F8F8)
    static let fogWhite = Color(hex: "F8F8F8")

    /// Soft Gray - Secondary Background (#EAEAEA)
    static let softGray = Color(hex: "EAEAEA")

    // MARK: - Dark Mode Colors (Phase 5)

    /// Dark Background - iOS standard dark background (#1C1C1E)
    static let darkBackground = Color(hex: "1C1C1E")

    /// Dark Card - Slightly lighter than background (#2C2C2E)
    static let darkCard = Color(hex: "2C2C2E")

    // MARK: - Adaptive Colors (Phase 5)

    /// Adaptive background - follows system color scheme
    static var adaptiveBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color.darkBackground)
                : UIColor(Color.fogWhite)
        })
    }

    /// Adaptive card background - follows system color scheme
    static var adaptiveCard: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color.darkCard)
                : UIColor(Color.softGray)
        })
    }

    // MARK: - Accent Colors (Same in Light/Dark)

    /// Amber - Gradient Start (#FFC46B)
    static let amber = Color(hex: "FFC46B")

    /// Azure - Gradient End (#9FD5FF)
    static let azure = Color(hex: "9FD5FF")

    // MARK: - Hex Initializer

    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    /// Amber to Azure gradient (Liquid Glass accent)
    static let amberToAzure = LinearGradient(
        colors: [.amber, .azure],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension AngularGradient {
    /// Circular gradient for progress rings
    static let circularAccent = AngularGradient(
        colors: [.amber, .azure, .amber],
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )
}

// MARK: - Material Extensions

extension Material {
    /// Liquid Glass material - ultra thin with subtle blur
    static let liquidGlass: Material = .ultraThinMaterial
}
