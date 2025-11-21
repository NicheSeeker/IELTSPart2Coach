//
//  StaticWaveformView.swift
//  IELTSPart2Coach
//
//  Static waveform visualization for playback
//  Displays the saved waveform (60 samples) with optional progress indicator
//

import SwiftUI

struct StaticWaveformView: View {
    let levels: [Float]
    let progress: Double // 0.0 to 1.0
    let showProgress: Bool // If true, bars before progress are highlighted

    init(levels: [Float], progress: Double = 0.0, showProgress: Bool = false) {
        self.levels = levels
        self.progress = progress
        self.showProgress = showProgress
    }

    var body: some View {
        Canvas { context, size in
            let barCount = levels.count
            guard barCount > 0 else { return }

            let barWidth: CGFloat = 3
            let spacing: CGFloat = 2
            let totalBarWidth = barWidth + spacing
            let totalWidth = CGFloat(barCount) * totalBarWidth - spacing

            // Center the waveform
            let startX = (size.width - totalWidth) / 2

            // Progress indicator position
            let progressIndex = Int(Double(barCount) * progress)

            for (index, level) in levels.enumerated() {
                let x = startX + CGFloat(index) * totalBarWidth
                let normalizedHeight = CGFloat(level) * size.height * 0.8
                let barHeight = max(normalizedHeight, 4) // Minimum 4pt height
                let y = (size.height - barHeight) / 2

                let barRect = CGRect(
                    x: x,
                    y: y,
                    width: barWidth,
                    height: barHeight
                )

                // Determine bar color
                let barColor: Color = if showProgress && index < progressIndex {
                    .amber // Already played (highlighted)
                } else {
                    Color.primary.opacity(0.3) // Not yet played (dim)
                }

                // Create rounded rectangle path
                let cornerRadius: CGFloat = 1.5
                let path = RoundedRectangle(cornerRadius: cornerRadius)
                    .path(in: barRect)

                // Fill with gradient
                let gradient = Gradient(colors: [
                    barColor,
                    barColor.opacity(0.7)
                ])

                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: barRect.origin,
                    endPoint: CGPoint(x: barRect.origin.x, y: barRect.maxY)
                ))
            }
        }
    }
}

// MARK: - Preview

#Preview("Static Waveform") {
    VStack(spacing: 32) {
        // Without progress
        StaticWaveformView(
            levels: (0..<60).map { _ in Float.random(in: 0.2...1.0) },
            showProgress: false
        )
        .frame(height: 60)
        .padding()

        // With progress (50%)
        StaticWaveformView(
            levels: (0..<60).map { _ in Float.random(in: 0.2...1.0) },
            progress: 0.5,
            showProgress: true
        )
        .frame(height: 60)
        .padding()

        // With progress (80%)
        StaticWaveformView(
            levels: (0..<60).map { _ in Float.random(in: 0.2...1.0) },
            progress: 0.8,
            showProgress: true
        )
        .frame(height: 60)
        .padding()
    }
    .background(Color.fogWhite)
}
