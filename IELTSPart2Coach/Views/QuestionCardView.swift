//
//  QuestionCardView.swift
//  IELTSPart2Coach
//
//  Main interface: Question Display + Recording + Playback
//  The heart of the Phase 1 experience
//

import SwiftUI

struct QuestionCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // ✅ FIX: Using @State with @Observable (iOS 17+ observation framework)
    // The viewModel is properly initialized once and won't be recreated on rebuilds
    // This prevents multiple Timer instances and state corruption on iPhone 16
    @State private var viewModel = RecordingViewModel()
    @State private var animateBreath = false
    @State private var showDurationHint = false
    @State private var showHistoryView = false  // Phase 7.2: History view control
    @State private var showSettingsView = false  // Phase 7.3: Settings view control
    @State private var hasInitialized = false  // ✅ FIX: Track initialization state
    @State private var isPromptsExpanded = false  // Phase 8.2: Collapsible prompts control

    // MARK: - Computed Properties

    /// Check if current error is daily limit error (hide Retry button)
    private var isDailyLimitError: Bool {
        if let error = viewModel.analysisError as? GeminiError {
            switch error {
            case .dailyLimitReached:
                return true
            default:
                return false
            }
        }
        return false
    }

    var body: some View {
        ZStack {
            // Background (Phase 5: Adaptive for Dark Mode)
            Color.adaptiveBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Question Card
                questionCard

                // Phase 9: Progress summary (only in idle state with data)
                if viewModel.state == .idle, let progress = viewModel.userProgress, progress.totalSessions >= 1 {
                    progressSummary(progress: progress)
                        .transition(.opacity)
                }

                Spacer()

                // Recording Interface
                recordingInterface

                Spacer()

                // Control Buttons
                controlButtons

                Spacer()
            }
            .padding()

            // Stop Button (fades in after 60s)
            if viewModel.showStopButton && viewModel.state == .recording {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        stopButton
                            .padding(.trailing, 32)
                            .padding(.bottom, 64)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }

            // Top Bar (only visible in idle state)
            if viewModel.state == .idle {
                VStack {
                    HStack {
                        historyButton
                        Spacer()
                        if StreakManager.shared.currentStreak > 0 {
                            streakBadge
                        }
                        Spacer()
                        settingsButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        // ✅ RESTORED: Interrupted session recovery Alert (now async, safe for startup)
        .alert("Welcome back", isPresented: Binding(
            get: { viewModel.hadInterruptedSession },
            set: { _ in viewModel.acknowledgeInterruptedSession() }
        )) {
            Button("Ready", role: .cancel) {
                viewModel.acknowledgeInterruptedSession()
            }
        } message: {
            Text("You stopped early last time. Ready to try again?")
        }
        .sheet(
            isPresented: $viewModel.showFeedbackSheet,
            onDismiss: {
                // Phase 7.4 Fix: Only trigger if user completed the practice (New Topic or Record Again)
                if viewModel.shouldTriggerNotificationFlowOnDismiss {
                    viewModel.shouldTriggerNotificationFlowOnDismiss = false  // Reset flag
                    Task {
                        // CRITICAL: Delay 300ms to avoid SwiftUI Sheet+Alert same-frame deadlock
                        // This prevents runloop blocking that causes Signal 9 on real devices
                        // Reference: https://stackoverflow.com/questions/66982492
                        try? await Task.sleep(for: .milliseconds(300))
                        await viewModel.handleNotificationPermissionFlow()
                    }
                }
            },
            content: {
                if let feedback = viewModel.feedbackResult {
                    FeedbackView(
                        feedback: feedback,
                        duration: viewModel.elapsedTime,
                        onPlayAgain: {
                            viewModel.playAgain()
                        },
                        onRecordAgain: {
                            Task {
                                await viewModel.recordAgain()
                            }
                        },
                        onNewTopic: {
                            // Phase 7.4 Fix: Save session/topic before reset() clears them
                            viewModel.savePendingNotificationData()
                            viewModel.shouldTriggerNotificationFlowOnDismiss = true
                            // Phase 8.2: Use AI topic generation instead of static topics
                            Task {
                                await viewModel.generateAITopic()
                            }
                            viewModel.showFeedbackSheet = false
                        },
                        isPlaying: viewModel.isPlaying,  // Phase 8.1 Fix: Dynamic button text
                        hasFinished: viewModel.hasFinishedPlayback,  // Phase 8.1 Fix: Four-state logic
                        playbackProgress: viewModel.playbackProgress,  // Phase 8.1 Fix: For Resume state
                        transcript: $viewModel.currentTranscript,  // Phase 8.1 Fix: Binding for reactive updates
                        nextFocusText: viewModel.nextFocusText  // Phase 9: Next action suggestion
                    )
                }
            }
        )
        .sheet(isPresented: $showHistoryView) {
            HistoryView()
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .alert(
            // Dynamic title based on error type
            isDailyLimitError ? "Daily Limit Reached" : "Analysis Failed",
            isPresented: Binding(
                get: { viewModel.analysisError != nil },
                set: { if !$0 { viewModel.analysisError = nil } }
            )
        ) {
            // Primary button (text varies by error type)
            Button(isDailyLimitError ? "Got it" : "OK", role: .cancel) {
                viewModel.analysisError = nil
            }

            // Retry button (hidden for daily limit errors)
            if !isDailyLimitError {
                Button("Retry") {
                    Task {
                        await viewModel.analyzeRecording()
                    }
                }
            }
        } message: {
            if let error = viewModel.analysisError {
                Text(error.localizedDescription)
            }
        }
        .alert("Recording Failed", isPresented: Binding(
            get: { viewModel.recordingError != nil },
            set: { if !$0 { viewModel.recordingError = nil } }
        )) {
            Button("Try Again", role: .cancel) {
                viewModel.recordingError = nil
                viewModel.startPreparation()
            }
            Button("Cancel") {
                viewModel.recordingError = nil
            }
        } message: {
            if let error = viewModel.recordingError {
                Text(error.localizedDescription + "\n\nNote: Simulator audio input may be unavailable. Try on a real device.")
            }
        }
        .alert("Get reminded to practice again?", isPresented: $viewModel.showNotificationPrePrompt) {
            Button("Yes, remind me") {
                Task {
                    await viewModel.acceptNotificationPrePrompt()
                }
            }
            Button("Not now", role: .cancel) {
                viewModel.denyNotificationPrePrompt()
            }
        } message: {
            Text("Get a notification in 3 days to practice this topic again.")
        }
        .overlay {
            // Phase 4.6: Transition overlay
            if viewModel.showTransitionOverlay {
                TransitionOverlay()
                    .transition(.opacity)
            }
        }
        .overlay {
            // Phase 8.2: Fallback toast notification
            ToastView(
                message: "Using backup topic. New AI topic will appear when online.",
                isPresented: $viewModel.showFallbackToast
            )
        }
        .task {
            // ✅ FIX: Defer initialization work to prevent main thread blocking
            // This runs asynchronously after the view appears
            guard !hasInitialized else { return }
            hasInitialized = true

            #if DEBUG
            print("✅ QuestionCardView initialized (deferred)")
            #endif

            // ✅ RESTORED: Async interrupted session detection (500ms delay for UI stability)
            // Wait for UI to fully stabilize before checking
            try? await Task.sleep(for: .milliseconds(500))

            // Only check if in idle state (avoid interfering with other flows)
            if viewModel.state == .idle {
                await viewModel.checkForInterruptedSessionAsync()
            }

            // Phase 8.2: Background AI topic generation (non-blocking)
            // Replace topics.json with AI-generated topic after app startup
            Task {
                await viewModel.generateAITopicInBackground()
            }
        }
    }

    // MARK: - Question Card

    private var questionCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Topic Title
                if let topic = viewModel.currentTopic {
                    // Main question
                    Text(topic.title)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                        .id(topic.id)  // Phase 8.2: Force view update on topic change
                        .transition(.opacity)  // Phase 8.2: 0.3s crossfade animation

                    // Phase 8.2: Prompts section (collapsible)
                    if let prompts = topic.prompts, !prompts.isEmpty {
                        // Show/Hide toggle
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .rotationEffect(.degrees(isPromptsExpanded ? 180 : 0))
                                .animation(.easeInOut(duration: 0.2), value: isPromptsExpanded)
                            Text(isPromptsExpanded ? "Hide details" : "Show details")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                        .foregroundStyle(.secondary)

                        // Prompts list (always in view hierarchy, visibility controlled by opacity/height)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.secondary)
                                    Text(prompt)
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: isPromptsExpanded ? nil : 0)
                        .opacity(isPromptsExpanded ? 1 : 0)
                        .clipped()
                        .animation(.easeInOut(duration: 0.2), value: isPromptsExpanded)
                    }
                } else {
                    Text("Loading topic...")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        // Phase 8.2: Tap entire card to toggle prompts
        // Animation handled by .animation() modifier on the VStack (Line 293)
        .onTapGesture {
            if let topic = viewModel.currentTopic,
               let prompts = topic.prompts,
               !prompts.isEmpty {
                isPromptsExpanded.toggle()
            }
        }
    }

    // MARK: - Recording Interface

    @ViewBuilder
    private var recordingInterface: some View {
        switch viewModel.state {
        case .idle:
            idleState

        case .preparing:
            preparingState

        case .recording:
            recordingState

        case .analyzing:
            analyzingState

        case .finished:
            finishedState
        }
    }

    private var idleState: some View {
        VStack(spacing: 20) {
            // Animated placeholder waveform
            AnimatedWaveform()
                .frame(height: 60)

            Text("Whenever you're ready")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Preparing State (Phase 4.5)

    private var preparingState: some View {
        PreparationView(
            timeLeft: viewModel.preparationTimeLeft,
            progress: viewModel.preparationProgress,
            showSkipButton: viewModel.showSkipButton,
            onSkip: {
                Task {
                    await viewModel.skipPreparation()
                }
            }
        )
    }

    private var recordingState: some View {
        VStack(spacing: 24) {
            // Progress Ring with Time
            ZStack {
                CircularProgressRing(
                    progress: viewModel.progress,
                    lineWidth: 12,
                    diameter: 180
                )

                VStack(spacing: 8) {
                    Text(viewModel.timeString)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .monospacedDigit()

                    Text("/ 02:00")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Live Waveform
            WaveformView(levels: viewModel.audioLevels)
                .frame(height: 60)

            // Duration hint (fade in/out)
            if showDurationHint {
                Text("Try to speak for about 1–2 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Fade in after 1 second
            withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
                showDurationHint = true
            }

            // Fade out after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showDurationHint = false
                }
            }
        }
        .onDisappear {
            // Reset hint state when leaving recording
            showDurationHint = false
        }
    }

    private var analyzingState: some View {
        VStack(spacing: 32) {
            // Breathing animation (Phase 5: Respects Reduce Motion)
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 180, height: 180)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .scaleEffect(reduceMotion ? 1.0 : (animateBreath ? 1.1 : 1.0))
                            .opacity(reduceMotion ? 0.7 : (animateBreath ? 0.5 : 1.0))
                            .animation(
                                reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: animateBreath
                            )
                    }

                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
            .onAppear {
                if !reduceMotion {
                    animateBreath = true
                }
            }
            .onDisappear {
                animateBreath = false
            }

            Text(viewModel.analysisStageText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var finishedState: some View {
        VStack(spacing: 24) {
            // Phase 5: Show BreathingRing when not playing, CircularProgressRing when playing
            ZStack {
                if viewModel.isPlaying {
                    // Playback mode: Show progress ring
                    CircularProgressRing(
                        progress: viewModel.playbackProgress,
                        lineWidth: 12,
                        diameter: 180,
                        onSeek: { progress in
                            viewModel.seekPlayback(to: progress)
                        }
                    )
                } else {
                    // Idle mode: Show breathing animation
                    BreathingRing(diameter: 180)
                }

                VStack(spacing: 8) {
                    // Playback time
                    Text(viewModel.playbackTimeString)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    // Total duration
                    Text("/ \(viewModel.timeString)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Static Waveform with Progress Indicator
            StaticWaveformView(
                levels: viewModel.savedWaveform,
                progress: viewModel.playbackProgress,
                showProgress: true
            )
            .frame(height: 60)
        }
    }

    // MARK: - Control Buttons

    @ViewBuilder
    private var controlButtons: some View {
        switch viewModel.state {
        case .idle:
            GlassButton("Start", style: .primary) {
                viewModel.startPreparation()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .accessibleButton(
                label: "Start practice",
                hint: "Begin 60-second preparation and recording"
            )

        case .preparing:
            EmptyView()  // Skip button is in PreparationView

        case .recording:
            EmptyView()

        case .analyzing:
            EmptyView()

        case .finished:
            VStack(spacing: 12) {
                // Core actions (top row)
                HStack(spacing: 16) {
                    GlassButton(viewModel.isPlaying ? "Pause" : "Play", style: .secondary) {
                        viewModel.togglePlayback()
                    }
                    .accessibleButton(
                        label: viewModel.isPlaying ? "Pause playback" : "Play recording",
                        hint: viewModel.isPlaying ? "Pause your recorded speech" : "Listen to your recording",
                        value: viewModel.isPlaying ? "Playing" : "Paused"
                    )

                    GlassButton("Get AI feedback", style: .primary) {
                        Task {
                            await viewModel.analyzeRecording()
                        }
                    }
                    .accessibleButton(
                        label: "Get AI feedback",
                        hint: "Analyze your speech and receive band scores"
                    )
                }

                // Secondary actions (bottom row)
                HStack(spacing: 16) {
                    GlassButton("Replay", style: .secondary) {
                        viewModel.replayRecording()
                    }
                    .accessibleButton(
                        label: "Replay from beginning",
                        hint: "Restart playback from the start"
                    )

                    GlassButton("New Topic", style: .secondary) {
                        Task {
                            await viewModel.generateAITopic()
                        }
                    }
                    .accessibleButton(
                        label: "New topic",
                        hint: "Load a different speaking topic"
                    )
                    .disabled(viewModel.isGeneratingTopic)  // Phase 8.2: Disable during generation
                }
            }
        }
    }

    // MARK: - Stop Button

    private var stopButton: some View {
        Button {
            viewModel.stopRecording()
        } label: {
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .accessibleButton(
            label: "Stop recording",
            hint: "End recording and listen to your speech"
        )
    }

    // MARK: - Settings Button (Phase 7.3)

    private var settingsButton: some View {
        Button {
            showSettingsView = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .padding(12)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
        }
        .accessibleButton(
            label: "Settings",
            hint: "Manage app settings and data"
        )
    }

    // MARK: - Streak Badge (Phase 9)

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)
            Text("\(StreakManager.shared.currentStreak) \(StreakManager.shared.currentStreak == 1 ? "day" : "days") streak")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Progress Summary (Phase 9)

    private func progressSummary(progress: UserProgress) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(progress.totalSessions)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("sessions")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1, height: 24)

            VStack(spacing: 2) {
                Text(progress.overallAverageString)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("avg band")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1, height: 24)

            VStack(spacing: 2) {
                Text(progress.weakestCategory)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange)
                Text("focus")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - History Button (Phase 7.2)

    private var historyButton: some View {
        Button {
            showHistoryView = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .padding(12)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
        }
        .accessibleButton(
            label: "Practice history",
            hint: "View your past recordings and feedback"
        )
    }
}

// MARK: - Transition Overlay (Phase 4.6)

private struct TransitionOverlay: View {
    @State private var currentPhase = 0  // 0: Get ready, 1: Start speaking

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            // Text switching (CrossFade)
            ZStack {
                if currentPhase == 0 {
                    Text("Get ready...")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }

                if currentPhase == 1 {
                    Text("Start speaking now")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }
            }
        }
        .allowsHitTesting(false)  // Disable interaction
        .onAppear {
            // Switch to phase 2 after 0.6s
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuestionCardView()
}
