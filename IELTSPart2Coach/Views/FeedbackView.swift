//
//  FeedbackView.swift
//  IELTSPart2Coach
//
//  Phase 4: Redesigned feedback view with minimal interactions
//  Phase 6: Added shimmer animation on initial reveal
//  Design: Calm, tap-to-reveal, anxiety-free
//

import SwiftUI

struct FeedbackView: View {
    let feedback: FeedbackResult
    let duration: TimeInterval
    let onPlayAgain: () -> Void
    let onRecordAgain: () -> Void
    let onNewTopic: () -> Void
    var historyMode: Bool = false  // Phase 7.2: Hide "Record Again" in history view
    var isPlaying: Bool = false    // Phase 7.2: Dynamic button text (Pause/Resume/Play Again)
    var hasFinished: Bool = false  // Phase 7.2: Track if playback completed naturally
    var playbackProgress: Double = 0  // Phase 8.1: Playback progress (0.0-1.0) for Resume state
    @Binding var transcript: String?  // Phase 8.1: Optional speech transcript (reactive)
    var nextFocusText: String? = nil  // Phase 9: Next action suggestion

    // MARK: - State

    @State private var revealedRing: BandCategory? = nil
    @State private var isTranscriptExpanded = false  // Phase 8.1: Transcript expand/collapse

    // MARK: - Computed Properties

    /// Four-state button text logic (Phase 8.1 Fix)
    /// Play → Pause → Resume → Pause → Play Again
    private var playbackButtonText: String {
        if isPlaying {
            return "Pause"       // State 1: Playing
        } else if hasFinished {
            return "Play Again"  // State 4: Completed
        } else if playbackProgress > 0 {
            return "Resume"      // State 3: Paused (played but not finished)
        } else {
            return "Play"        // State 2: Initial (never played)
        }
    }

    /// Phase 8.1: Check if transcript should be shown
    private var shouldShowTranscript: Bool {
        // Require both: Settings enabled AND transcript available
        guard let transcript = transcript, !transcript.isEmpty else {
            return false
        }
        return UserDefaults.standard.isTranscriptEnabled
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Micro-Advice Card (Summary + Tip)
                    MicroAdviceCard(
                        summary: feedback.summary,
                        actionTip: feedback.actionTip
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)

                    // Quote Box (conditional)
                    QuoteBox(quote: feedback.quote)
                        .padding(.horizontal)

                    // Band Scores Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("IELTS Band Scores")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal)

                        // 2x2 Ring Grid
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(BandCategory.allCases, id: \.self) { category in
                                BandScoreRing(
                                    title: category.displayTitle,
                                    score: getScore(for: category),
                                    isRevealed: Binding(
                                        get: { revealedRing == category },
                                        set: { _ in }
                                    ),
                                    onTap: { handleRingTap(category) }
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Expanded Comment (full-width, conditional)
                        if let revealed = revealedRing {
                            Text(getScore(for: revealed).comment)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                                        removal: .opacity
                                    )
                                )
                        }
                    }

                    // Transcript Section (Phase 8.1, conditional on Settings toggle)
                    if shouldShowTranscript {
                        transcriptSection
                    }

                    // Duration Hint (if recording was short)
                    if duration < 60 {
                        let qualifier = duration < 15 ? "very " : duration < 30 ? "fairly " : ""

                        Text("This score reflects the \(qualifier)short length of your answer.")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }

                    // Phase 9: Next action prompt
                    if let focusText = nextFocusText {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)

                            Text(focusText)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                        .padding(.horizontal)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        if historyMode {
                            // History Mode: Only Play/Pause + Close
                            HStack(spacing: 12) {
                                Button {
                                    onPlayAgain()
                                } label: {
                                    Text(playbackButtonText)  // Phase 7.2 Fix: Three-state (Pause/Resume/Play Again)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.gray.opacity(0.3))
                                        }
                                }
                                .accessibleButton(
                                    label: playbackButtonText,
                                    hint: isPlaying ? "Pause the audio" : (hasFinished ? "Play recording from the beginning" : "Play the recording")
                                )

                                Button {
                                    onNewTopic()
                                } label: {
                                    Text("Close")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.blue)
                                        }
                                }
                                .accessibleButton(
                                    label: "Close",
                                    hint: "Return to history view"
                                )
                            }
                        } else {
                            // Normal Mode: Row 1 - Primary actions (replay/re-record)
                            HStack(spacing: 12) {
                                Button {
                                    onPlayAgain()
                                } label: {
                                    Text(playbackButtonText)  // Phase 8.1 Fix: Dynamic text (Play/Pause/Resume/Play Again)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.gray.opacity(0.3))
                                        }
                                }
                                .accessibleButton(
                                    label: playbackButtonText,
                                    hint: isPlaying ? "Pause the audio" : (hasFinished ? "Play recording from the beginning" : "Play the recording")
                                )

                                Button {
                                    onRecordAgain()
                                } label: {
                                    Text("Practice Again")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.orange)
                                        }
                                }
                                .accessibleButton(
                                    label: "Practice again",
                                    hint: "Practice this topic again with a new recording"
                                )
                            }

                            // Row 2: Secondary action (new topic)
                            Button {
                                onNewTopic()
                            } label: {
                                Text("New Topic")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.blue)
                                    }
                            }
                            .accessibleButton(
                                label: "New topic",
                                hint: "Load a different speaking topic"
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .shimmer(duration: 1.8, delay: 0.3)  // Phase 6: Shimmer on feedback reveal
            }
        }
    }

    // MARK: - Helper Methods

    /// Handle ring tap (exclusive reveal logic)
    private func handleRingTap(_ category: BandCategory) {
        withAnimation(.easeOut(duration: 0.4)) {
            if revealedRing == category {
                revealedRing = nil  // Collapse if tapping same ring
            } else {
                revealedRing = category  // Reveal new, collapse previous
            }
        }
    }

    /// Get score for specific band category
    private func getScore(for category: BandCategory) -> BandScore {
        switch category {
        case .fluency:       return feedback.bands.fluency
        case .lexical:       return feedback.bands.lexical
        case .grammar:       return feedback.bands.grammar
        case .pronunciation: return feedback.bands.pronunciation
        }
    }

    // MARK: - Transcript Section (Phase 8.1)

    /// Transcript display with filler word highlighting
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header with expand/collapse button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTranscriptExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Transcript")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: isTranscriptExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content (transcript text)
            if isTranscriptExpanded {
                if let transcript = transcript, !transcript.isEmpty {
                    Text(transcript)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                } else {
                    Text("Transcript unavailable")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Band Category Enum

enum BandCategory: String, CaseIterable {
    case fluency
    case lexical
    case grammar
    case pronunciation

    var displayTitle: String {
        switch self {
        case .fluency:       return "Fluency"
        case .lexical:       return "Lexical"
        case .grammar:       return "Grammar"
        case .pronunciation: return "Pronunciation"
        }
    }
}

// MARK: - Preview

#Preview {
    FeedbackView(
        feedback: FeedbackResult(
            summary: "Your story was engaging and easy to follow — your tone feels confident and natural.",
            actionTip: "Try varying your sentence rhythm to sound even more natural when linking ideas.",
            bands: BandScores(
                fluency: BandScore(score: 6.5, comment: "Good pacing, but a few long pauses."),
                lexical: BandScore(score: 6.5, comment: "Accurate word choice, could add more descriptive language."),
                grammar: BandScore(score: 6.0, comment: "Generally correct sentences, but some repetition of basic forms."),
                pronunciation: BandScore(score: 6.5, comment: "Clear articulation with minor stress inconsistencies.")
            ),
            quote: "Actually I think it was when my teacher encouraged me to try again."
        ),
        duration: 25.0,
        onPlayAgain: {
            print("Play Again tapped")
        },
        onRecordAgain: {
            print("Practice Again tapped")
        },
        onNewTopic: {
            print("New Topic tapped")
        },
        transcript: .constant("This is a sample transcript for preview purposes.")  // Phase 8.1 Fix: Binding
    )
}
