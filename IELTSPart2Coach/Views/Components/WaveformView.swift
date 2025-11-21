//
//  WaveformView.swift
//  IELTSPart2Coach
//
//  Real-time audio waveform visualization
//  Uses Canvas API for smooth, performant rendering
//

import SwiftUI

struct WaveformView: View {
    let levels: [Float]
    let barWidth: CGFloat
    let spacing: CGFloat
    let maxHeight: CGFloat

    init(
        levels: [Float],
        barWidth: CGFloat = 4,
        spacing: CGFloat = 3,
        maxHeight: CGFloat = 60
    ) {
        self.levels = levels
        self.barWidth = barWidth
        self.spacing = spacing
        self.maxHeight = maxHeight
    }

    var body: some View {
        // Phase 5: Lock to 30fps for better performance and battery life
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let barCount = levels.count
                guard barCount > 0 else { return }

                let totalBarWidth = barWidth + spacing
                let startX = (size.width - CGFloat(barCount) * totalBarWidth) / 2

                for (index, level) in levels.enumerated() {
                    let x = startX + CGFloat(index) * totalBarWidth
                    let height = max(4, CGFloat(level) * maxHeight)
                    let y = (size.height - height) / 2

                    let barRect = CGRect(
                        x: x,
                        y: y,
                        width: barWidth,
                        height: height
                    )

                    let path = RoundedRectangle(
                        cornerRadius: barWidth / 2,
                        style: .continuous
                    )
                    .path(in: barRect)

                    // Gradient fill
                    let gradient = Gradient(colors: [
                        Color.amber.opacity(0.8),
                        Color.azure.opacity(0.8)
                    ])

                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: x, y: y),
                            endPoint: CGPoint(x: x, y: y + height)
                        )
                    )
                }
            }
            .frame(height: maxHeight)
        }
    }
}

// MARK: - Animated Waveform (for idle state)

struct AnimatedWaveform: View {
    @State private var phase: CGFloat = 0

    let barCount: Int
    let barWidth: CGFloat
    let spacing: CGFloat
    let maxHeight: CGFloat

    init(
        barCount: Int = 20,
        barWidth: CGFloat = 4,
        spacing: CGFloat = 3,
        maxHeight: CGFloat = 60
    ) {
        self.barCount = barCount
        self.barWidth = barWidth
        self.spacing = spacing
        self.maxHeight = maxHeight
    }

    var body: some View {
        // Phase 5: Lock to 30fps for better performance and battery life
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let totalBarWidth = barWidth + spacing
                let startX = (size.width - CGFloat(barCount) * totalBarWidth) / 2

                for index in 0..<barCount {
                    let x = startX + CGFloat(index) * totalBarWidth

                    // Sine wave for smooth animation
                    let normalizedIndex = CGFloat(index) / CGFloat(barCount)
                    let waveValue = sin(normalizedIndex * .pi * 2 + phase)
                    let height = max(4, (waveValue * 0.5 + 0.5) * maxHeight * 0.6)

                    let y = (size.height - height) / 2

                    let barRect = CGRect(
                        x: x,
                        y: y,
                        width: barWidth,
                        height: height
                    )

                    let path = RoundedRectangle(
                        cornerRadius: barWidth / 2,
                        style: .continuous
                    )
                    .path(in: barRect)

                    // Gradient fill
                    let gradient = Gradient(colors: [
                        Color.amber.opacity(0.4),
                        Color.azure.opacity(0.4)
                    ])

                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: x, y: y),
                            endPoint: CGPoint(x: x, y: y + height)
                        )
                    )
                }
            }
            .frame(height: maxHeight)
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = .pi * 2
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Static Waveform") {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Low levels
            WaveformView(levels: [0.2, 0.3, 0.25, 0.35, 0.3, 0.28, 0.32, 0.27])

            // Medium levels
            WaveformView(levels: [0.4, 0.6, 0.5, 0.7, 0.6, 0.55, 0.65, 0.5])

            // High levels
            WaveformView(levels: [0.7, 0.9, 0.8, 1.0, 0.85, 0.9, 0.95, 0.8])
        }
        .padding()
    }
}

#Preview("Animated Waveform") {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        AnimatedWaveform()
            .padding()
    }
}
