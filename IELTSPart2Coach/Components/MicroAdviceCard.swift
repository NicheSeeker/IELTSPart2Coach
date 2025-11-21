//
//  MicroAdviceCard.swift
//  IELTSPart2Coach
//
//  Phase 4: Minimal advice card (Summary + Action Tip)
//  Phase 6: Added shimmer wave animation on appear (respects Reduce Motion)
//

import SwiftUI

struct MicroAdviceCard: View {
    let summary: String
    let actionTip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            Text(summary)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .lineSpacing(4)

            // Divider
            Divider()
                .opacity(0.2)

            // Action Tip
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Text(actionTip)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .shimmer(duration: 1.5, delay: 0.2)  // Phase 6: One-time shimmer wave
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MicroAdviceCard(
            summary: "Your story was engaging and easy to follow — your tone feels confident and natural.",
            actionTip: "Try varying your sentence rhythm to sound even more natural when linking ideas."
        )

        MicroAdviceCard(
            summary: "You expressed your ideas clearly, but in just a few words.",
            actionTip: "Aim to speak for 1–2 minutes to show your full range."
        )
    }
    .padding()
    .background(Color.fogWhite)
}
