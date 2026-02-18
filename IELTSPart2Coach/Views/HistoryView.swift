//
//  HistoryView.swift
//  IELTSPart2Coach
//
//  Phase 7.2: Practice history interface
//  Displays sessions grouped by date with playback and delete functionality
//

import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.adaptiveBackground
                .ignoresSafeArea()

            if viewModel.sessions.isEmpty {
                // Empty state
                emptyState
            } else {
                // Session list
                sessionList
            }
        }
        .task {
            await viewModel.loadSessions()
        }
        .sheet(isPresented: $viewModel.showPlaybackSheet) {
            // ✅ FIX: Stop playback when sheet is dismissed (by swipe or button)
            // This ensures audio doesn't continue playing in background
            viewModel.stopPlayback()
        } content: {
            // Playback Sheet (Phase 7.2 - Step 4)
            if let session = viewModel.selectedSession {
                playbackSheet(for: session)
            }
        }
        .alert(viewModel.deleteError is HistoryError ? "Playback Failed" : "Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.deleteError = nil
            }
        } message: {
            if let error = viewModel.deleteError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.3))

            // Message
            VStack(spacing: 8) {
                Text("No recordings yet")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Start practicing to see your history here")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Page title
                Text("Practice History")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .padding(.top, 24)

                // Grouped sessions
                ForEach(viewModel.groupedSessions, id: \.dateString) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date header
                        Text(group.dateString)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        // Sessions in this group
                        ForEach(group.sessions) { session in
                            SessionCard(session: session) {
                                Task {
                                    await viewModel.playSession(session)
                                }
                            }
                            .padding(.horizontal)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteSession(session)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteSession(session)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Bottom padding
                Spacer()
                    .frame(height: 40)
            }
        }
    }

    // MARK: - Playback Sheet

    @ViewBuilder
    private func playbackSheet(for session: PracticeSession) -> some View {
        if let feedback = session.feedback {
            // Session has feedback: Show FeedbackView in history mode
            FeedbackView(
                feedback: feedback,
                duration: session.duration,
                onPlayAgain: {
                    viewModel.togglePlayback()
                },
                onRecordAgain: {
                    // Not applicable in history mode
                    // This button will be hidden via historyMode parameter
                },
                onNewTopic: {
                    viewModel.stopPlayback()
                    viewModel.showPlaybackSheet = false
                },
                historyMode: true,  // Phase 7.2: Hide "Record Again" button
                isPlaying: viewModel.isPlaying,  // Phase 7.2 Fix: Pass playback state for dynamic button text
                hasFinished: viewModel.hasFinishedPlayback,  // Phase 7.2 Fix: Three-state button logic
                transcript: .constant(session.transcript),  // Phase 8.1 Fix: Pass historical transcript
                nextFocusText: nil  // Phase 9: No action prompt in history mode
            )
        } else {
            // Session without feedback: Show minimal playback interface
            PlaybackOnlyView(
                session: session,
                viewModel: viewModel,
                onDismiss: {
                    viewModel.stopPlayback()
                    viewModel.showPlaybackSheet = false
                }
            )
        }
    }
}

// MARK: - Playback-Only View (No Feedback)

private struct PlaybackOnlyView: View {
    let session: PracticeSession
    @Bindable var viewModel: HistoryViewModel
    let onDismiss: () -> Void

    /// Three-state button text logic (Phase 7.2)
    private var playbackButtonText: String {
        if viewModel.isPlaying {
            return "Pause"
        } else if viewModel.hasFinishedPlayback {
            return "Play Again"
        } else {
            return "Play"
        }
    }

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Topic title
                LiquidGlassCard {
                    Text(session.topicTitle)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal)

                // Playback interface
                VStack(spacing: 24) {
                    // Progress ring + time (with scrubbing support)
                    ZStack {
                        CircularProgressRing(
                            progress: viewModel.playbackProgress,
                            lineWidth: 12,
                            diameter: 180,
                            onSeek: { progress in
                                viewModel.seekPlayback(toProgress: progress)
                            }
                        )

                        VStack(spacing: 8) {
                            Text(viewModel.playbackTimeString)
                                .font(.system(size: 42, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)

                            Text("/ \(session.durationString)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Waveform (if available)
                    // TODO: Extract waveform from audio file
                }

                Spacer()

                // Control buttons
                HStack(spacing: 16) {
                    GlassButton(playbackButtonText, style: .secondary) {  // Phase 7.2 Fix: Three-state logic
                        viewModel.togglePlayback()
                    }

                    GlassButton("Close", style: .secondary) {
                        onDismiss()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}
