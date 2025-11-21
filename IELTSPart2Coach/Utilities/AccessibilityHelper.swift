//
//  AccessibilityHelper.swift
//  IELTSPart2Coach
//
//  Phase 5: Accessibility ViewModifiers for VoiceOver and Dynamic Type
//  Phase 6: Added Reduce Motion support with breathing, pulse, and shimmer animations
//  Provides custom modifiers for accessible buttons, text, and animations
//

import SwiftUI

// MARK: - Animation ViewModifiers (Phase 6)

/// ViewModifier that adds a calm breathing animation (scale + opacity pulse)
/// Automatically respects Reduce Motion preference
struct BreathingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let duration: TimeInterval
    let scaleRange: ClosedRange<CGFloat>

    init(duration: TimeInterval = 2.0, scaleRange: ClosedRange<CGFloat> = 0.95...1.05) {
        self.duration = duration
        self.scaleRange = scaleRange
    }

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : (isAnimating ? scaleRange.upperBound : scaleRange.lowerBound))
            .opacity(reduceMotion ? 1.0 : (isAnimating ? 1.0 : 0.85))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// ViewModifier that adds a subtle pulse animation (scale only)
/// Converts to opacity-only animation if Reduce Motion is enabled
struct PulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let duration: TimeInterval
    let scaleAmount: CGFloat

    init(duration: TimeInterval = 1.5, scaleAmount: CGFloat = 1.02) {
        self.duration = duration
        self.scaleAmount = scaleAmount
    }

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        if reduceMotion {
            // Reduce Motion: Only subtle opacity change
            content
                .opacity(isAnimating ? 0.95 : 1.0)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
        } else {
            // Normal: Scale + opacity
            content
                .scaleEffect(isAnimating ? scaleAmount : 1.0)
                .opacity(isAnimating ? 0.95 : 1.0)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
        }
    }
}

/// ViewModifier that adds a shimmer wave effect (plays once)
/// Completely disabled if Reduce Motion is enabled
struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let duration: TimeInterval
    let delay: TimeInterval

    init(duration: TimeInterval = 1.5, delay: TimeInterval = 0.0) {
        self.duration = duration
        self.delay = delay
    }

    @State private var shimmerOffset: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.easeOut(duration: duration)) {
                                    shimmerOffset = geometry.size.width + 200
                                }
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Animation View Extensions (Phase 6)

extension View {
    /// Apply calm breathing animation (scale + opacity pulse)
    /// Automatically respects Reduce Motion - becomes static when enabled
    /// - Parameters:
    ///   - duration: Animation cycle duration (default: 2.0s, tune on real device)
    ///   - scaleRange: Scale range for breathing effect (default: 0.95...1.05)
    func breathing(
        duration: TimeInterval = 2.0,
        scaleRange: ClosedRange<CGFloat> = 0.95...1.05
    ) -> some View {
        modifier(BreathingModifier(duration: duration, scaleRange: scaleRange))
    }

    /// Apply subtle pulse animation (scale + opacity)
    /// Converts to opacity-only when Reduce Motion is enabled
    /// - Parameters:
    ///   - duration: Animation cycle duration (default: 1.5s)
    ///   - scaleAmount: Maximum scale amount (default: 1.02)
    func pulse(
        duration: TimeInterval = 1.5,
        scaleAmount: CGFloat = 1.02
    ) -> some View {
        modifier(PulseModifier(duration: duration, scaleAmount: scaleAmount))
    }

    /// Apply shimmer wave effect (plays once)
    /// Completely disabled when Reduce Motion is enabled
    /// - Parameters:
    ///   - duration: Shimmer animation duration (default: 1.5s)
    ///   - delay: Delay before shimmer starts (default: 0.0s)
    func shimmer(
        duration: TimeInterval = 1.5,
        delay: TimeInterval = 0.0
    ) -> some View {
        modifier(ShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - VoiceOver & Dynamic Type ViewModifiers (Phase 5)

extension View {
    /// Make a button accessible with VoiceOver support
    /// - Parameters:
    ///   - label: Accessibility label (what the button does)
    ///   - hint: Optional hint for additional context
    ///   - value: Optional current value (e.g., "Playing" for a play/pause button)
    func accessibleButton(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Make text accessible with proper labeling
    /// - Parameters:
    ///   - label: Accessibility label (alternative description)
    ///   - value: Optional value (for dynamic content)
    func accessibleText(
        label: String,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
    }

    /// Make text support Dynamic Type with graceful degradation
    /// Phase 5: Uses lineLimit and minimumScaleFactor to prevent layout breaks
    func dynamicTypeSupport(
        lineLimit: Int = 2,
        minimumScale: Double = 0.8
    ) -> some View {
        self
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScale)
    }

    /// Make a score ring accessible for VoiceOver
    /// - Parameters:
    ///   - category: Band category name (e.g., "Fluency")
    ///   - score: Numeric score (e.g., 6.5)
    ///   - comment: Comment text
    ///   - isRevealed: Whether the detail is currently shown
    func accessibleScoreRing(
        category: String,
        score: Double,
        comment: String,
        isRevealed: Bool
    ) -> some View {
        self
            .accessibilityLabel("\(category) score \(score, specifier: "%.1f")")
            .accessibilityHint(isRevealed ? comment : "Double tap to hear feedback")
            .accessibilityValue(isRevealed ? "Expanded" : "Collapsed")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Helper Extensions

extension Text {
    /// Apply standard Dynamic Type support for body text
    func bodyDynamicType() -> some View {
        self
            .lineLimit(3)
            .minimumScaleFactor(0.8)
    }

    /// Apply standard Dynamic Type support for titles
    func titleDynamicType() -> some View {
        self
            .lineLimit(2)
            .minimumScaleFactor(0.85)
    }

    /// Apply standard Dynamic Type support for compact text (buttons, labels)
    func compactDynamicType() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
