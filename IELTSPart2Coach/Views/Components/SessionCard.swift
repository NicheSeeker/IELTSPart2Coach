//
//  SessionCard.swift
//  IELTSPart2Coach
//
//  Phase 7.2: Practice session list item
//  Displays topic, duration, and feedback summary (if available)
//

import SwiftUI

struct SessionCard: View {
    let session: PracticeSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Left: Waveform icon
                Image(systemName: "waveform")
                    .font(.system(size: 24))
                    .foregroundStyle(session.hasFeedback ? Color.amber : .secondary)
                    .frame(width: 40)

                // Center: Content
                VStack(alignment: .leading, spacing: 6) {
                    // Topic title
                    Text(session.topicTitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Metadata row
                    HStack(spacing: 8) {
                        // Duration
                        Text(session.durationString)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)

                        // Feedback score (if available)
                        if let feedback = session.feedback {
                            Text("•")
                                .foregroundStyle(.secondary.opacity(0.5))

                            Text("Overall \(feedback.bands.averageDisplayScore)")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Right: Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(PlainButtonStyle())  // Prevent default button styling
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        // Session with feedback
        SessionCard(
            session: PracticeSession(
                id: UUID(),
                topicID: UUID(),
                topicTitle: "Describe a memorable childhood experience that taught you something important.",
                audioFileName: "session_test.m4a",
                duration: 107,
                feedback: FeedbackResult(
                    summary: "Great job!",
                    actionTip: "Keep practicing",
                    bands: BandScores(
                        fluency: BandScore(score: 6.5, comment: "Good pacing"),
                        lexical: BandScore(score: 6.5, comment: "Nice vocabulary"),
                        grammar: BandScore(score: 6.0, comment: "Solid grammar"),
                        pronunciation: BandScore(score: 6.5, comment: "Clear speech")
                    ),
                    quote: "Actually I think..."
                )
            ),
            onTap: { print("Tapped") }
        )

        // Session without feedback
        SessionCard(
            session: PracticeSession(
                id: UUID(),
                topicID: UUID(),
                topicTitle: "Talk about a place you like to go to relax.",
                audioFileName: "session_test2.m4a",
                duration: 89,
                feedback: nil
            ),
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
