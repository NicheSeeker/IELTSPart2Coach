//
//  CircularProgressRing.swift
//  IELTSPart2Coach
//
//  Circular progress ring with Liquid Glass gradient
//  Smooth animations following iOS 26 design principles
//

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let diameter: CGFloat
    let onSeek: ((Double) -> Void)? // Optional scrubbing callback

    @State private var isDragging = false
    @State private var dragProgress: Double?

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        diameter: CGFloat = 180,
        onSeek: ((Double) -> Void)? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.diameter = diameter
        self.onSeek = onSeek
    }

    // Displayed progress (drag takes priority)
    private var displayedProgress: Double {
        dragProgress ?? progress
    }

    var body: some View {
        ZStack {
            // Background ring (subtle)
            Circle()
                .stroke(
                    Color.softGray.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.amber, .azure, .amber]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(isDragging ? .none : .linear(duration: 0.3), value: displayedProgress)

            // Glow effect
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    Color.azure.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: lineWidth + 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 4)
                .animation(isDragging ? .none : .linear(duration: 0.3), value: displayedProgress)
        }
        .frame(width: diameter, height: diameter)
        .gesture(
            onSeek != nil ? DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let newProgress = calculateProgress(from: value.location)
                    dragProgress = newProgress
                }
                .onEnded { value in
                    let finalProgress = calculateProgress(from: value.location)
                    onSeek?(finalProgress)
                    dragProgress = nil
                    isDragging = false
                }
            : nil
        )
    }

    // MARK: - Helper Methods

    /// Calculate progress (0.0 - 1.0) from touch location
    private func calculateProgress(from location: CGPoint) -> Double {
        // Center of the circle
        let center = CGPoint(x: diameter / 2, y: diameter / 2)

        // Vector from center to touch point
        let dx = location.x - center.x
        let dy = location.y - center.y

        // Calculate angle in radians
        var angle = atan2(dy, dx)

        // Adjust to start from top (0° = top, clockwise)
        angle += .pi / 2

        // Normalize to 0...2π
        if angle < 0 {
            angle += 2 * .pi
        }

        // Convert to progress (0.0 - 1.0)
        let progress = angle / (2 * .pi)

        return max(0, min(1, progress))
    }
}

// MARK: - Breathing Animation (Phase 6: Upgraded to use unified .breathing() modifier)

struct BreathingRing: View {
    let diameter: CGFloat

    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.amber.opacity(0.5), .azure.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 8
            )
            .frame(width: diameter, height: diameter)
            .opacity(0.5)  // Base opacity
            .breathing(duration: 2.0, scaleRange: 0.9...1.1)  // Phase 6: Unified breathing animation
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Static progress examples
            CircularProgressRing(progress: 0.25)
            CircularProgressRing(progress: 0.5)
            CircularProgressRing(progress: 0.75)

            // Breathing animation
            BreathingRing(diameter: 180)
        }
    }
}

#Preview("Animated Progress") {
    struct AnimatedPreview: View {
        @State private var progress: Double = 0

        var body: some View {
            ZStack {
                Color.fogWhite
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    CircularProgressRing(progress: progress)

                    Text("\(Int(progress * 100))%")
                        .font(.title.weight(.medium))

                    GlassButton("Animate") {
                        withAnimation {
                            progress = progress >= 1.0 ? 0 : progress + 0.25
                        }
                    }
                }
            }
        }
    }

    return AnimatedPreview()
}
