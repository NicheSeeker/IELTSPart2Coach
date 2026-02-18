//
//  LiquidGlassCard.swift
//  IELTSPart2Coach
//
//  Reusable card component with iOS 26 Liquid Glass effect
//  Features: translucent blur, subtle shadows, elegant depth
//  Phase 5: Added Dark Mode support with adaptive materials
//

import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        highlightColor.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        highlightColor.opacity(0.3),
                                        highlightColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(shadowOpacity * 0.6), radius: 4, x: 0, y: 2)
    }

    // MARK: - Adaptive Styles (Phase 5)

    /// Material adapts based on color scheme
    /// Light Mode: ultraThin (more transparent)
    /// Dark Mode: regular (thicker, better contrast)
    private var cardMaterial: Material {
        colorScheme == .dark ? .regularMaterial : .ultraThinMaterial
    }

    /// Highlight color for gradients
    private let highlightColor = Color.white

    /// Shadow opacity adapts to background
    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.05
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        VStack(spacing: 20) {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Liquid Glass Card")
                        .font(.title2.weight(.medium))

                    Text("This demonstrates the iOS 26 Liquid Glass design language with translucent blur and subtle depth.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            LiquidGlassCard {
                Text("Compact Card")
                    .font(.headline)
            }
        }
        .padding()
    }
}
