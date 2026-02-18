//
//  QuoteBox.swift
//  IELTSPart2Coach
//
//  Phase 4: Minimal quote display
//  Phase 6: Upgraded to use unified .pulse() modifier from AccessibilityHelper
//

import SwiftUI

struct QuoteBox: View {
    let quote: String

    var body: some View {
        if !quote.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary.opacity(0.6))

                Text("\"\(quote)\"")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .italic()
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            .pulse(duration: 2.0, scaleAmount: 1.01)  // Phase 6: Subtle continuous pulse
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With quote
        QuoteBox(quote: "Actually I think it was when my teacher encouraged me to try again.")

        // Empty quote (should not render)
        QuoteBox(quote: "")

        // Short quote
        QuoteBox(quote: "It was amazing.")
    }
    .padding()
    .background(Color.fogWhite)
}
