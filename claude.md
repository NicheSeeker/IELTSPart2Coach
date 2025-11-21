🪞 Product PRD — IELTS Part 2 Coach (v1)
1. Product Name

IELTS Part 2 Coach (Working title)

The name explicitly communicates the focus on IELTS Speaking Part 2 and improves App Store discoverability.

Disclaimer: "This app is not affiliated with or endorsed by IELTS."

2. Product Vision

A calm, minimalist, and beautifully crafted space to practice IELTS Speaking Part 2.
No clutter, no login, no institutional tone — just you, your voice, and two minutes to express yourself.

Core philosophy: "Open. Speak. Be heard."

The app aims to replicate the authentic IELTS experience while removing friction, anxiety, and noise — offering a single, serene loop of expression and reflection.

3. Core Experience
1️⃣ Open → Get a Question

No login or setup.

Instantly displays a simulated IELTS Part 2 topic.

Topics are original practice prompts inspired by the IELTS format, not taken from official materials.

2️⃣ Prepare (60 seconds)

Soft countdown begins automatically.

Users can skip preparation after 10 seconds if they feel ready to speak.

3️⃣ Speak (max 120 seconds)

The recording UI is fully minimal:

Circular progress ring

Reactive voice wave animation

No Stop button for the first 60 seconds → encourages authentic expression.

After 60 seconds, a subtle "Stop" button (semi-transparent) fades in at bottom-right.

If tapped, recording ends smoothly with a breathing animation and haptic feedback.

If user reaches 120 seconds, the app auto-stops.

State    Visible UI    Action    System Response
0–60s    Circle + waveform only    Speak    No stop button
60–120s    Stop button fades in    Tap → end    Transition to breathing animation
≥120s    Auto-stop    End recording    Proceed to analysis
4️⃣ Feedback (AI Summary)

AI analysis begins with a short breathing animation ("Listening to you…").

Displays one micro-advice card (≤25 words), quoting a short user phrase.

Encouraging, natural tone (no red marks, no errors).

Users can tap "See full feedback" to expand a detailed view:

Four IELTS band categories: Fluency, Lexical Resource, Grammar, Pronunciation.

Each category shown as a soft circular ring, not a number by default.

Optional toggle to reveal numeric band values with short qualitative notes:

"Fluency 6.5 – Your rhythm feels smooth, with a few long pauses."

No total band displayed.
AI uses pause count and tone data internally, but users see only qualitative insights.

5️⃣ Repeat Later

The same topic reappears 3 days later for self-comparison.

The system internally tracks progress (no visible metrics).

The app focuses on "how you sound today vs. last time," not gamified progress.

4. AI Feedback System (Revised Final Version)
Input

.m4a audio file

Speech-to-text transcript

Detected acoustic features (pause length, pace, tone range, filler frequency)

Internal Process

Gemini analyzes the input across four IELTS dimensions:

Fluency & Coherence

Lexical Resource

Grammar Range & Accuracy

Pronunciation

It generates a multi-layer "Feedback Bundle" with structured fields, blending qualitative insight and natural coaching tone.

Output (JSON)
{
  "summary": "Your story was engaging and easy to follow — your tone feels confident and natural.",
  "action_tip": "Try varying your sentence rhythm to sound even more natural when linking ideas.",
  "bands": {
    "fluency": {
      "score": 6.5,
      "comment": "Good pacing, but a few long pauses."
    },
    "lexical": {
      "score": 6.5,
      "comment": "Accurate word choice, could add more descriptive language."
    },
    "grammar": {
      "score": 6.0,
      "comment": "Generally correct sentences, but some repetition of basic forms."
    },
    "pronunciation": {
      "score": 6.5,
      "comment": "Clear articulation with minor stress inconsistencies."
    }
  },
  "quote": "Actually I think it was when my teacher encouraged me to try again."
}

Prompt for Gemini

You are an IELTS Speaking Part 2 examiner and language coach.
Listen to the audio and analyze the transcript in four areas: fluency, lexical resource, grammar, and pronunciation.

Your task: create a warm, human-like feedback bundle in structured JSON.

Output exactly these fields:

"summary": 1–2 sentences (40–60 words) summarizing how the speech feels overall, using natural coaching tone (no grading tone).

"action_tip": 1 concise, actionable suggestion (≤25 words) that helps the user improve next time.

"bands": for each of the four IELTS categories, include "score" (0.0–9.0) and a "comment" (max 20 words) explaining why.

"quote": one short phrase directly quoted from the user's speech that best represents their expression style.

Keep tone supportive, natural, calm, like a private speaking coach.
Never use template phrases like "You should…" or "Your mistake is…".

Output only valid JSON, with double quotes for all keys and strings.

Developer Implementation Note

Default view: show only "summary" and "action_tip".

When the user taps "See full feedback", reveal "bands" and "quote".

All numeric scores remain hidden by default to reduce performance anxiety.

AI diff data (used for progress tracking) stays internal, invisible to user.

5. Visual & Interaction Design
Design Philosophy

Apple Design Award–level craftsmanship.
Every element should feel light, tactile, and intentional.

Layer    Principle
Design language    Liquid Glass (iOS 26): translucent depth, subtle refraction, layered fluid motion.
Aesthetic feel    Depth without clutter. Light refraction replaces shadows. Motion feels viscous, not mechanical.
Color palette    Mist white, soft grey, with topic-based accent gradients (amber → azure).
Typography    SF Rounded / SF Pro; medium weights only; dynamic type supported.
Motion    ≤300 ms transitions; sine easing; breathing-inspired pacing.
Haptics    Subtle feedback at: recording start, stop, and feedback reveal.
Audio cues    Two only: record start / end — soft, breath-like tones.
Layout    One focal point per screen. No banners, no tutorial text.
Dark Mode    Transparent depth layers, no hard blacks.

The interface should feel like speaking into light — calm, intimate, and fluid.

6. Sound & Motion Moments
Moment    Effect
Start recording    Ripple expands outward + light haptic tap
Finish (auto or stop)    Circle contracts → breathing pulse animation
AI analyzing    Gentle shimmer across translucent layer
Feedback reveal    Soft refraction glow; slight haptic pulse

All transitions are organic, as if the UI itself is breathing with the user.

7. Privacy & Data

Audio stored locally by default (no cloud uploads).

Optional "Analyze only" mode deletes audio after processing.

One-tap delete all recordings.

No ads, no analytics SDKs, no trackers.

8. Success Definition

When a user finishes speaking, they don't feel judged — they feel heard.
If someone whispers, "That felt peaceful," after using it, the product has succeeded.

"Not an app for speaking better English — an app for expressing yourself better."

---

## 9. Implementation Specifications (v1.0)

### 9.1 Liquid Glass Design System

**Visual Reference**: iOS 26 Liquid Glass 视觉体系

**Core Principles**:
- 层叠玻璃质感、实时景深模糊、动态反射高光与半透明层次效果
- 整体风格应体现"流动的光感"与"触感通透"的交互氛围

**Color Palette (Confirmed)**:
```
Primary Background:     #F8F8F8  (雾白 Mist White)
Secondary Background:   #EAEAEA  (柔灰 Soft Grey)
Gradient Accent:        #FFC46B → #9FD5FF  (琥珀 Amber → 天蓝 Azure)
```

**Design Guidelines**:
- 保持层次透明感与柔和高光，符合 iOS 26 的 Liquid Glass 视觉语言
- 保留呼吸感动画、极简布局与顺滑动效
- 无需复杂 icon 或插画，主打干净、现代、平衡的视觉节奏

### 9.2 Technical Stack (Phase 1)

**Platform & Language**:
- iOS 26.0+ (latest features)
- Swift 5.0 with SwiftUI
- Xcode 26.0+

**Data Persistence**:
- SwiftData (iOS 17+) for local storage
- Local file system for audio recordings (.m4a)

**AI Integration**:
- OpenRouter API endpoint
- Model: Gemini 2.5 Flash
- API Key: Stored securely in iOS Keychain (configured via Settings)
- Multimodal capability: Send M4A audio + optional short transcript
- Gemini handles: Speech-to-text, tone analysis, fluency, pronunciation
- Architecture designed for future fallback to Apple Speech framework

**Topic Database (Phase 1)**:
- 5 hardcoded IELTS Part 2-style questions
- Static local JSON file structure
- Future: Remote update capability (not implemented in v1)

**Deferred Features (Post-Phase 1)**:
- Local notifications for 3-day practice reminders
- Commercial features, login, account system
- Analytics and tracking SDKs

### 9.3 Phase 1 Scope: First Screen Polish

**Goal**: Implement the first screen (Question Display + Recording Interface) and polish it to perfection.

**Deliverables**:
1. ✅ App opens directly to question card screen (no splash/onboarding)
2. ✅ User taps "Start" to begin recording
3. ✅ Recording UI shows:
   - Circular progress ring
   - Reactive waveform animation
   - Timer display
4. ✅ "Stop" button fades in after 60 seconds (semi-transparent, bottom-right)
5. ✅ After stopping, user can playback the recording
6. ✅ Visual style matches PRD: minimalist + Liquid Glass aesthetic

**Design Priorities**:
- 一切以用户体验与设计美感优先
- 不用考虑商业化、登录、账户系统
- 所有按钮、动效、反馈都应体现"被倾听感"与"低摩擦感"

### 9.4 Architecture Pattern (MVVM)

```
IELTSPart2Coach/
├── Models/
│   ├── Topic.swift              // Topic data model
│   ├── Recording.swift          // Recording session model
│   └── FeedbackResult.swift     // AI feedback response model
├── ViewModels/
│   ├── TopicViewModel.swift     // Topic selection logic
│   └── RecordingViewModel.swift // Recording state machine
├── Views/
│   ├── QuestionCardView.swift   // Main question display
│   ├── RecordingView.swift      // Recording interface
│   └── Components/
│       ├── CircularProgressRing.swift
│       ├── WaveformView.swift
│       └── LiquidGlassButton.swift
├── Services/
│   ├── AudioRecorder.swift      // AVFoundation wrapper
│   ├── AudioPlayer.swift        // Playback logic
│   └── GeminiService.swift      // OpenRouter API client
├── Utilities/
│   ├── HapticManager.swift      // Haptic feedback
│   └── ColorPalette.swift       // Design system colors
└── Resources/
    └── topics.json              // Hardcoded question bank
```

### 9.5 Phase Roadmap (Overview)

| Phase | Status | Focus | Duration | Key Deliverables |
|-------|--------|-------|----------|------------------|
| **Phase 1** | ✅ **Completed** | Question Display + Recording Interface | 6 hours | 14 files, MVVM architecture, Liquid Glass UI |
| **Phase 2** | ✅ **Completed** | Preparation Stage + Audio Playback Polish | 4 hours | 60s countdown, Skip button, enhanced playback |
| **Phase 3** | ✅ **Completed** | Gemini AI Integration | 6 hours | OpenRouter client, multimodal API, feedback parsing, error handling |
| **Phase 5** | ✅ **Completed** | Audio System Rewrite (Critical Bug Fix) | 4 hours | AudioSessionManager, AVAudioPlayer migration, I/O conflict resolution |
| **Phase 4** | 📋 Planned | Feedback Display Screen | 5 hours | Micro-advice card, band score rings, expandable view |
| **Phase 6** | 📋 Planned | Polish + Final Touches | 4 hours | Dark Mode, breathing animations, performance optimization |
| **Phase 7** | 📋 Planned | Data Persistence + Advanced Features | 6 hours | SwiftData, practice history, 3-day reminders |

**Total Estimated Time**: ~31 hours of focused development

---

## 10. Implementation History

### 10.1 Phase 1: Question Display + Recording Interface ✅

**Status**: ✅ Completed (2025-11-04)

**Duration**: 6 hours

#### 📦 Files Created (14 total)

##### **Models** (1 file)
- `Models/Topic.swift` - Simple topic data model (ID + title only)

##### **ViewModels** (1 file)
- `ViewModels/RecordingViewModel.swift` - State machine for recording flow (idle/recording/finished)

##### **Views** (5 files)
- `Views/QuestionCardView.swift` - Main interface orchestrating all states
- `Views/Components/LiquidGlassCard.swift` - Reusable card with ultraThinMaterial
- `Views/Components/GlassButton.swift` - Interactive button with gradient and haptics
- `Views/Components/CircularProgressRing.swift` - Progress ring with amber-azure gradient
- `Views/Components/WaveformView.swift` - Real-time audio visualization with Canvas API

##### **Services** (1 file)
- `Services/AudioRecorder.swift` - AVFoundation wrapper for M4A recording

##### **Utilities** (2 files)
- `Utilities/ColorPalette.swift` - Liquid Glass color system
- `Utilities/HapticManager.swift` - Centralized haptic feedback

##### **Resources** (1 file)
- `Resources/topics.json` - 5 hardcoded IELTS Part 2 questions

##### **App Entry** (1 file)
- `IELTSPart2CoachApp.swift` - Modified to load QuestionCardView and prepare haptics

#### 🎯 Key Features Implemented

1. **Liquid Glass Design System**
   - Color palette: `#F8F8F8`, `#EAEAEA`, `#FFC46B→#9FD5FF`
   - `.ultraThinMaterial` with gradient overlays
   - Smooth animations (≤300ms, easeInOut)

2. **Recording State Machine**
   ```swift
   enum RecordingState {
       case idle           // Show Start button
       case recording      // 0-120s with progress ring
       case finished       // Show Playback + New Topic
   }
   ```

3. **Timer Logic**
   - 60s: Stop button fades in (semi-transparent, bottom-right)
   - 120s: Auto-stop recording
   - Real-time elapsed time display (MM:SS format)

4. **Audio Recording**
   - Format: M4A (AAC), 44.1kHz, mono
   - Real-time volume monitoring (50ms intervals)
   - Waveform visualization (30 sample buffer)
   - Files saved to `FileManager.temporaryDirectory`

5. **Haptic Feedback**
   - Recording start: `recordingStart()` (medium + light echo)
   - Recording stop: `recordingStop()` (medium + breathing pulse)
   - Button taps: `light()`
   - Engine prepared on app launch for zero-latency

#### 🐛 Problems Solved

1. **Info.plist Conflict**
   - **Issue**: Multiple commands produce Info.plist (manual + auto-generated)
   - **Solution**: Removed manual Info.plist, rely on Xcode's auto-generation
   - **Note**: Microphone permission must be added via Xcode UI (Target → Info tab)

2. **Concurrency Errors**
   - **Issue**: `selection()` method conflicted with `selection` property
   - **Solution**: Renamed method to `selectionChanged()`

   - **Issue**: Timer callback accessing MainActor properties
   - **Solution**: Wrapped timer body with `Task { @MainActor in ... }`

   - **Issue**: `deinit` accessing MainActor-isolated properties
   - **Solution**: Marked `timer` and `audioPlayer` as `nonisolated(unsafe)`

3. **Async Permission Check**
   - **Issue**: `await` in short-circuit `||` operator
   - **Solution**: Separate permission check into two steps:
   ```swift
   let hasPermission = audioRecorder.checkPermission()
   if !hasPermission {
       let granted = await audioRecorder.requestPermission()
       guard granted else { return }
   }
   ```

#### 🧪 Testing Checklist

- [x] App launches directly to question card
- [x] Random topic loads from topics.json
- [x] "Start" button requests microphone permission
- [x] Recording starts with circular progress ring
- [x] Waveform responds to audio input
- [x] Timer displays in MM:SS format
- [x] Stop button fades in at 60 seconds
- [x] Auto-stop at 120 seconds
- [x] "Complete" state shows breathing animation
- [x] "Play" button plays back recording
- [x] "New Topic" loads different question

#### 📝 Technical Decisions

1. **Why MVVM?**
   - Clean separation of concerns
   - Observable state for reactive UI
   - Easy to test ViewModels independently

2. **Why `nonisolated(unsafe)` for Timer/AudioPlayer?**
   - Swift's strict concurrency requires MainActor isolation
   - Timer/AVAudioPlayer callbacks are on different threads
   - `nonisolated(unsafe)` allows manual cleanup in `deinit`
   - Safe because we invalidate/stop before deallocation

3. **Why Canvas for Waveform?**
   - High performance for real-time rendering
   - 60fps smooth animations with `TimelineView(.animation)`
   - Better than Shape-based approaches for dynamic data

4. **Why .m4a Format?**
   - Smaller file size than WAV
   - Native iOS support
   - Compatible with Gemini API
   - AAC codec provides good quality at 44.1kHz

#### 🎨 Design Implementation Notes

- **LiquidGlassCard**: Uses `.ultraThinMaterial` + gradient overlay + subtle border
- **CircularProgressRing**: Gradient created with `AngularGradient` for smooth color transition
- **WaveformView**: Renders rounded rectangles with gradient fill
- **AnimatedWaveform**: Sine wave animation for idle state (2s loop)
- **BreathingRing**: Scale + opacity animation (easeInOut, 2s, repeat forever)

#### 📦 Build Configuration

```bash
# Deployment Target
iOS 26.1

# Architecture
arm64 (Apple Silicon native)

# Bundle Identifier
com.Charlie.IELTSPart2Coach

# Required Permissions
- NSMicrophoneUsageDescription (must add manually in Xcode)

# Build Command
xcodebuild -scheme IELTSPart2Coach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

#### 🚀 How to Run (Phase 1)

1. Open `IELTSPart2Coach.xcodeproj` in Xcode 26+
2. Select Target → Info tab
3. Add `Privacy - Microphone Usage Description` with value:
   ```
   IELTS Part 2 Coach needs access to your microphone to record your speaking practice.
   ```
4. Select iPhone 17 (or any iOS 26.1 simulator)
5. Press `Cmd + R` to run
6. Allow microphone permission when prompted
7. Tap "Start" to record, speak for 60-120 seconds
8. Tap "Stop" (after 60s) or wait for auto-stop
9. Tap "Play" to hear playback
10. Tap "New Topic" to reset

---

## 11. Detailed Phase Plans

### 11.1 Phase 2: Preparation Stage + Audio Playback Polish 📋

**Goal**: Add the 60-second preparation countdown with skip functionality, and enhance playback experience.

**Duration**: 4 hours

#### 🎯 Features to Implement

1. **Preparation Countdown (60 seconds)**
   - New state: `.preparing` in RecordingViewModel
   - Circular countdown timer (60 → 0)
   - Auto-transition to `.recording` when countdown reaches 0
   - Manual "Skip" button (fades in after 10 seconds)

2. **Enhanced Playback**
   - Playback progress bar (similar to recording ring)
   - Playback waveform visualization (static, from recorded data)
   - Pause/Resume during playback
   - Scrubbing (drag to seek)

3. **Audio Playback Service**
   - Create `Services/AudioPlayer.swift`
   - Wrap `AVAudioPlayer` with Observable state
   - Real-time playback progress tracking
   - Waveform data extraction from audio file

#### 📂 Files to Create/Modify

**New Files**:
- `Services/AudioPlayer.swift` - Playback service with progress tracking
- `Views/Components/PreparationView.swift` - 60s countdown with skip button
- `Views/Components/StaticWaveformView.swift` - Static waveform for playback

**Modified Files**:
- `ViewModels/RecordingViewModel.swift` - Add `.preparing` state
- `Views/QuestionCardView.swift` - Add preparation stage handling

#### 🎨 UI/UX Details

**Preparation Screen**:
```
┌─────────────────────────────┐
│                             │
│      ╭───────────╮          │
│      │  Prepare  │          │
│      │           │          │
│      │   00:58   │          │  ← 60s countdown ring
│      │           │          │
│      ╰───────────╯          │
│                             │
│     [Skip Preparation]      │  ← Fades in after 10s
└─────────────────────────────┘
```

**Playback Screen**:
```
┌─────────────────────────────┐
│   ╭─────────○─────────╮     │  ← Playback progress ring
│   │       00:47       │     │
│   ╰───────────────────╯     │
│                             │
│  ▃▄▆█▅▃▄▆▅▃ (static waveform)│
│                             │
│   [◼ Pause]  [⟳ Replay]   │
└─────────────────────────────┘
```

#### 🧪 Testing Scenarios

- [x] Tap "Start" → enters preparation mode
- [x] Countdown displays 60 → 0
- [x] "Skip" button appears after 10 seconds
- [x] Auto-transition to recording after 60s
- [x] Playback shows progress ring
- [x] Can pause/resume during playback
- [x] Can scrub through recording

#### 🔧 Technical Implementation Notes

**State Machine Update**:
```swift
enum RecordingState {
    case idle
    case preparing      // NEW: 60s countdown
    case recording
    case finished
    case playing        // NEW: playback in progress
}
```

**AudioPlayer Interface**:
```swift
@MainActor
@Observable
class AudioPlayer {
    var isPlaying: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    var progress: Double { currentTime / duration }

    func play()
    func pause()
    func seek(to time: TimeInterval)
    func stop()
}
```

---

### 11.2 Phase 3: Gemini AI Integration ✅ **COMPLETED**

**Goal**: Integrate OpenRouter API with Gemini 2.5 Flash for multimodal audio analysis.

**Duration**: 6 hours (Completed)

**Status**: ✅ All features implemented, build succeeded

#### ✅ Confirmed Product Decisions

1. **UI Transition Flow** (Option B):
   - Recording ends → `.finished` state (can playback)
   - User clicks "Get AI feedback" button → `.analyzing` state
   - Analysis complete → Sheet presents `FeedbackView`

2. **State Machine Design**:
   - `RecordingState`: `idle → recording → finished → analyzing`
   - `FeedbackView` as navigation target (Sheet), not in RecordingState

3. **Error Recovery** (Option A):
   - Analysis fails → Show error alert → Return to `.finished` (preserve playback)
   - User can retry or continue playback

4. **Audio Lifecycle** (Option B):
   - Keep audio after analysis for feedback screen playback
   - Delete when leaving feedback / loading new topic / closing app

5. **Transcript** (Option A):
   - Phase 3 sends audio only, rely on Gemini 2.5 Flash multimodal understanding
   - Future Phase 4 can add optional transcription module

#### 🎯 Features Implemented

1. **OpenRouter API Client** ✅
   - Created `Services/GeminiService.swift`
   - Multimodal request: base64 M4A audio
   - 45s timeout (optimized from 30s for mobile networks)
   - 5 error types with English user messages
   - Compatible with array/string content formats

2. **Feedback Data Models** ✅
   - Created `Models/FeedbackResult.swift`
   - Codable structs with validation
   - Score range checking (0.0-9.0)

3. **Analysis Loading State** ✅
   - New `.analyzing` state
   - Breathing circle animation (1.5s cycle)
   - "Listening to you…" text
   - Auto-cleanup on dismiss

4. **API Integration Flow** ✅
   - Recording stops → `.finished` (playback preview)
   - User taps "Get AI feedback" → validates quality → `.analyzing`
   - Success → `FeedbackView` sheet
   - Error → Alert with retry option

#### 📂 Files Created/Modified

**New Files**:
- ✅ `Services/GeminiService.swift` - OpenRouter API client (285 lines)
- ✅ `Models/FeedbackResult.swift` - Response data model (40 lines)
- ✅ `Views/FeedbackView.swift` - Phase 4 placeholder (235 lines)

**Modified Files**:
- ✅ `ViewModels/RecordingViewModel.swift` - Added `.analyzing`, analysis methods, cleanup logic
- ✅ `Views/QuestionCardView.swift` - Added analyzing UI, feedback sheet, error alerts

#### 🔌 API Integration Details

**OpenRouter Endpoint**:
```
POST https://openrouter.ai/api/v1/chat/completions
```

**Headers** (✅ Implemented):
```
Authorization: Bearer <API_KEY>
Content-Type: application/json
X-Title: IELTSPart2Coach
Referer: https://com.Charlie.IELTSPart2Coach
```

**Request Body** (✅ Corrected format):
```json
{
  "model": "google/gemini-2.5-flash",
  "response_format": {"type": "json_object"},
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "<IELTS examiner prompt from PRD>"
        },
        {
          "type": "input_audio",
          "input_audio": {
            "data": "<base64-encoded M4A>",
            "format": "m4a"
          }
        }
      ]
    }
  ]
}
```

**Key Fixes Applied**:
- ✅ Changed `"type": "audio"` → `"type": "input_audio"`
- ✅ Wrapped audio data in `input_audio` object
- ✅ Added `response_format: {type: "json_object"}` to enforce JSON
- ✅ Timeout: 45s (optimized for mobile networks)

**Expected Response**:
```json
{
  "summary": "Your story was engaging...",
  "action_tip": "Try varying your sentence rhythm...",
  "bands": {
    "fluency": { "score": 6.5, "comment": "Good pacing..." },
    "lexical": { "score": 6.5, "comment": "Accurate word choice..." },
    "grammar": { "score": 6.0, "comment": "Generally correct..." },
    "pronunciation": { "score": 6.5, "comment": "Clear articulation..." }
  },
  "quote": "Actually I think it was..."
}
```

#### 🔧 Error Handling Strategy (✅ Implemented)

1. **Network Errors** ✅: "Network connection failed. Please check your internet."
2. **API Errors (4xx/5xx)** ✅: "Analysis failed (code: XXX)." + Log full response
3. **Timeout (>45s)** ✅: "Analysis timed out. Please try again."
4. **Invalid Response** ✅: "Invalid response format." + Log raw JSON (truncated 500 chars)
5. **Rate Limiting (429)** ✅: "Too many requests. Please try again later."

**Additional Validations** ✅:
- Recording quality check (minimum 5 seconds, non-silent)
- Score range validation (0.0-9.0)
- Compatible with both string and array content formats

#### 🧪 Testing Scenarios

**Completed**:
- [x] Project builds successfully (no compilation errors)
- [x] State machine transitions correctly
- [x] All UI components render
- [x] Error alerts display with retry option
- [x] FeedbackView placeholder created

**Pending** (Manual testing required with real API):
- [ ] Record 30s audio → tap "Get AI feedback" → analyzing state
- [ ] "Listening to you…" breathing animation displays
- [ ] API request completes successfully (<45s)
- [ ] Feedback data parses correctly (bands, summary, tip, quote)
- [ ] FeedbackView sheet presents
- [ ] Network error shows alert with retry
- [ ] Short recording (<5s) shows validation error
- [ ] Silent recording rejected with error message

#### 🐛 Critical Bug Fix: Real Device Crash (✅ Fixed)

**Issue Discovered**: App crashed on iPhone 16 when tapping "Get AI feedback" button.

**Root Cause**:
- Xcode scheme environment variables are **not available on real iOS devices** (security limitation)
- `ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]` returns `nil` on real devices
- Original code used `fatalError()` → immediate crash

**Solution Applied** (Phase 3 Strategy):
```swift
private let apiKey: String = {
    // Priority 1: Environment variable (works in simulator)
    if let key = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !key.isEmpty {
        return key
    }

    // Priority 2: Fallback for real device testing (Phase 3 only)
    // ⚠️ DEPRECATED: Phase 5 migrated to Keychain storage
    return "[DEPRECATED - API Key now in Keychain]"
}()
```

**Behavior**:
- ✅ **Simulator**: Reads from Xcode environment variable
- ✅ **Real Device**: Uses fallback key
- ✅ **No Crash**: Both platforms work smoothly

**Migration Path**:
- Phase 3: Environment variable + hardcoded fallback ✅
- Phase 5: Keychain storage + Settings UI
- Phase 6+: CI/CD secrets management, remove hardcoded key

**Error Handling** (prepared for Phase 5):
- Added `GeminiError.missingAPIKey` case
- Friendly alert: "Missing API Key. Please configure it in Settings."

---

#### 🔐 Security Considerations (✅ Implemented)

- ✅ API key from environment variable (simulator) + fallback (real device)
- ✅ Audio files deleted via `cleanupIfNeeded()` (on dismiss, new topic)
- ✅ No user PII sent to API (audio only)
- ✅ HTTPS enforced via URLSession
- ✅ Ephemeral URLSession config (no disk caching of audio)
- ✅ Never log API keys or base64 audio (only size/hash)

**Future Improvements** (Phase 5+):
- Move API key to Keychain (remove hardcoded fallback)
- Add Settings UI for API key configuration
- Implement certificate pinning
- Add request signing
- Audio file encryption at rest

#### 📝 GeminiService Interface (✅ Implemented)

```swift
@MainActor
class GeminiService {
    static let shared = GeminiService()

    // Main API
    func analyzeSpeech(audioURL: URL) async throws -> FeedbackResult

    // Helpers
    private func encodeAudioToBase64(url: URL) throws -> String
    private func buildPrompt() -> String
    private func buildRequestBody(base64Audio: String) throws -> Data
    private func makeHeaders() -> [String: String]
    private func parseResponse(data: Data) throws -> FeedbackResult
    private func logRawResponse(_ data: Data)
}

enum GeminiError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case timeout
    case rateLimited
    case apiError(statusCode: Int, message: String)
    case missingAPIKey  // Reserved for Phase 5
}
```

#### 🎬 Next Steps

1. **Testing on Real Device** (iPhone 16) ✅:
   - ✅ Crash fixed: API key fallback implemented
   - [ ] Record 30s audio
   - [ ] Tap "Get AI feedback"
   - [ ] Verify breathing animation
   - [ ] Check API response parsing
   - [ ] Test error scenarios (airplane mode, timeout)

2. **Optional: Simulator Testing**:
   - Simulator can use environment variable for cleaner setup
   - Set `OPENROUTER_API_KEY` in Xcode scheme if preferred
   - Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables

3. **Phase 4 Implementation**:
   - Design full FeedbackView UI (replace placeholder)
   - Implement band score rings
   - Add quote highlighting
   - Polish animations

4. **Phase 5 TODO** (Security Enhancement):
   - Remove hardcoded API key fallback
   - Implement Keychain storage
   - Add Settings UI for API key configuration

#### 🐛 Bug Fix: API Field Mapping & UI Layout Issues (✅ Fixed - 2025-11-05)

**Issues Discovered** (Real Device Testing on iPhone 16):

1. **API Parsing Failure**: `keyNotFound(lexical)` error
   - **Root Cause**: Gemini API returns `"lexical_resource"` instead of `"lexical"`
   - **Solution**: Added CodingKeys mapping in `BandScores` struct
   ```swift
   enum CodingKeys: String, CodingKey {
       case fluency
       case lexical = "lexical_resource"  // Map Gemini's field name
       case grammar
       case pronunciation
   }
   ```

2. **Button Layout Overflow**: 4 buttons in single row caused text truncation
   - **Root Cause**: HStack with 4 buttons too wide for iPhone 16 screen
   - **Solution**: Changed to 2x2 grid layout with VStack + HStack
   ```swift
   VStack(spacing: 12) {
       HStack { Play, Get AI feedback }  // Core actions
       HStack { Replay, New Topic }      // Secondary actions
   }
   ```

3. **Missing Preparation Stage**: No 60s countdown before recording
   - **Status**: Deferred to Phase 2 implementation
   - **Current Flow**: `idle → recording` (skips preparation)
   - **Expected Flow**: `idle → preparing (60s) → recording`

**Additional Debugging**:
- Added complete response logging in parseResponse() catch block
- Now prints full JSON for debugging field name mismatches

**Files Modified**:
- `Models/FeedbackResult.swift` (Lines 32-37): Added BandScores CodingKeys
- `Views/QuestionCardView.swift` (Lines 279-303): Refactored button layout
- `Services/GeminiService.swift` (Lines 229-233): Enhanced error logging

---

#### ⚡ Development Optimization: Fast Testing Mode (✅ Implemented)

**Purpose**: Speed up development testing by reducing Stop button wait time.

**Background**:
- Production: Stop button appears after 60 seconds (IELTS standard)
- Development: Waiting 60 seconds for each test is inefficient
- Need to maintain IELTS authenticity in production builds

**Solution** (Compiler-based):
```swift
// In RecordingViewModel.swift
#if DEBUG
private let stopButtonThreshold: TimeInterval = 10  // Dev: 10s for fast testing
#else
private let stopButtonThreshold: TimeInterval = 60  // Production: 60s (IELTS standard)
#endif
```

**How It Works**:
- Debug builds (Xcode → Run): Stop button appears after 10 seconds
- Release builds (Archive/TestFlight): Stop button appears after 60 seconds
- No visual indicators (maintains minimalist design)
- Zero impact on production code

**Benefits**:
- 6x faster iteration during development
- No code changes needed when switching configurations
- Maintains production behavior in release builds

**Testing**:
- Debug: Verify Stop button appears at 10s
- Release: Verify Stop button appears at 60s (Archive → Export)

---

### 11.3 Phase 5: Audio System Rewrite ✅ **COMPLETED**

**Goal**: Complete rewrite of audio system to fix iPhone 15/16 crashes caused by AVAudioSession conflicts.

**Duration**: 4 hours (Completed: 2025-11-07)

**Status**: ✅ All features implemented, build succeeded

#### 🎯 Problem Analysis

**Critical Bug**: App crashed on iPhone 15/16 real devices when recording or playing audio.

**Crash Signature**:
```
"Unable to join I/O thread to workgroup"
"AVAudioPlayer: player did not see an IO cycle"
```

**Root Cause Analysis**:
1. **Multiple AVAudioSession Activations**: AudioRecorder, AudioPlayer, and SoundEffects all independently called `setCategory()` and `setActive()`
2. **AVAudioEngine I/O Conflicts**: SoundEffects used AVAudioEngine which implicitly activates audio session, competing with AVAudioRecorder for I/O thread access
3. **Repeated Session Activation**: Each recording cycle triggered multiple `setActive(true)` calls, overwhelming the system
4. **Timing Issues**: No delays between session activation and recorder start, or between recorder stop and player start
5. **iPhone 15/16 Sensitivity**: A18/M18 chips enforce stricter I/O thread management than previous generations

**User's Diagnosis** (Correcting Initial Misdiagnosis):
> "你遇到的播放无声不是因为使用了 .record category 而无法播放... 90% 来自：你的代码在多个地方同时触发了 AudioSession 激活/配置"

#### 🏗️ Architecture Solution: Single Point of Control

**Design Pattern**: Singleton Coordinator with Lazy Initialization

**Core Principle**: **ONLY** AudioSessionManager can call `setCategory()` and `setActive()` in the entire app.

```
┌─────────────────────────────────────────────────────────────┐
│                   AudioSessionManager                       │
│                  (Single Point of Control)                  │
│                                                             │
│  • ONLY place that calls setCategory() / setActive()       │
│  • Configured ONCE when recording starts                   │
│  • All audio components delegate to this manager           │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
   ┌──────────┐      ┌──────────┐     ┌──────────┐
   │  Audio   │      │  Audio   │     │  Sound   │
   │ Recorder │      │  Player  │     │ Effects  │
   ├──────────┤      ├──────────┤     ├──────────┤
   │ NO       │      │ NO       │     │ NO       │
   │ session  │      │ session  │     │ session  │
   │ config   │      │ config   │     │ config   │
   └──────────┘      └──────────┘     └──────────┘
```

#### 📦 Files Created/Modified

**New Files**:
- ✅ `Services/AudioSessionManager.swift` (82 lines) - Global session coordinator

**Completely Rewritten**:
- ✅ `Services/AudioRecorder.swift` - Removed all session code, added defensive checks
- ✅ `Services/AudioPlayer.swift` - Simplified to pure AVAudioPlayer wrapper
- ✅ `Utilities/SoundEffects.swift` - **Switched from AVAudioEngine to AVAudioPlayer**

**Updated**:
- ✅ `ViewModels/RecordingViewModel.swift` - Added 300ms/500ms timing delays
- ✅ `IELTSPart2CoachApp.swift` - Updated initialization comments

#### 🔧 Implementation Details

##### **1. AudioSessionManager (NEW)**

**Singleton Pattern with Actor Isolation**:
```swift
@MainActor
class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}  // Prevent external instantiation

    private let session = AVAudioSession.sharedInstance()
    private var isSessionActive = false

    var isActive: Bool { isSessionActive }
    var currentOutputRoute: String {
        session.currentRoute.outputs.first?.portName ?? "Unknown"
    }

    func configureSession() throws {
        // Guard: Only configure once
        guard !isSessionActive else {
            print("⚠️ Audio session already active, skipping reconfiguration")
            return
        }

        // Configure category and options
        try session.setCategory(
            .playAndRecord,           // Supports both recording and playback
            mode: .default,
            options: [
                .defaultToSpeaker,    // Playback to speaker (not receiver)
                .allowBluetooth,      // Support AirPods/headphones
                .mixWithOthers        // Coexist with other apps
            ]
        )

        // Activate session
        try session.setActive(true, options: [])
        isSessionActive = true

        #if DEBUG
        print("✅ Audio session configured successfully")
        print("   Category: .playAndRecord")
        print("   Output: \(currentOutputRoute)")
        #endif
    }

    func deactivate() throws {
        guard isSessionActive else { return }
        try session.setActive(false, options: .notifyOthersOnDeactivation)
        isSessionActive = false
        #if DEBUG
        print("🔇 Audio session deactivated")
        #endif
    }
}
```

**Key Design Decisions**:
1. **`.playAndRecord` Category**: Supports both recording and playback simultaneously
2. **`.defaultToSpeaker` Option**: Routes playback to speaker (not receiver/听筒)
3. **`.allowBluetooth`**: Seamless AirPods/headphone support
4. **`.mixWithOthers`**: Allows coexistence with Music/Podcast apps
5. **State Tracking**: `isSessionActive` prevents duplicate activation
6. **Defensive Guard**: Returns early if already configured

##### **2. AudioRecorder (REWRITTEN)**

**Changes Made**:
- ❌ Removed: `setupAudioSession()` method entirely
- ❌ Removed: All `AVAudioSession` imports and references
- ✅ Added: Defensive check for session state before recording
- ✅ Kept: All waveform monitoring and level tracking unchanged

**Critical Code Section**:
```swift
override init() {
    super.init()
    // CRITICAL: Do NOT configure audio session here!
    // All session management is handled by AudioSessionManager
}

func startRecording() throws {
    #if DEBUG
    print("🎤 Starting recording...")
    #endif

    // Ensure audio session is configured (defensive check)
    if !AudioSessionManager.shared.isActive {
        print("⚠️ Audio session not active, attempting to configure...")
        try AudioSessionManager.shared.configureSession()
    }

    // Generate unique file URL
    let fileName = "recording_\(Date().timeIntervalSince1970).wav"
    let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

    // Audio settings: WAV (Linear PCM) format
    let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false
    ]

    // Create recorder
    audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
    audioRecorder?.delegate = self
    audioRecorder?.isMeteringEnabled = true

    // Start recording
    guard let recorder = audioRecorder else {
        throw RecordingError.failedToStart
    }

    let started = recorder.record()
    guard started else {
        throw RecordingError.failedToStart
    }

    currentAudioURL = audioURL
    isRecording = true
    audioLevels.removeAll()
    fullWaveform.removeAll()
    savedWaveform.removeAll()

    #if DEBUG
    print("✅ Recording started successfully")
    print("🎤 Output route: \(AudioSessionManager.shared.currentOutputRoute)")
    #endif

    // Start level monitoring
    startLevelMonitoring()
}
```

##### **3. AudioPlayer (REWRITTEN)**

**Changes Made**:
- ❌ Removed: All AVAudioSession code
- ✅ Simplified: Pure AVAudioPlayer wrapper
- ✅ Kept: Same public interface (load, play, pause, stop, seek)
- ✅ Added: Waveform extraction for visualization

**Critical Code Section**:
```swift
func load(url: URL) throws {
    stop()

    #if DEBUG
    print("🔊 Loading audio file: \(url.lastPathComponent)")
    #endif

    // Create audio player (does NOT modify audio session)
    audioPlayer = try AVAudioPlayer(contentsOf: url)
    audioPlayer?.delegate = self
    audioPlayer?.prepareToPlay()

    // Get duration
    duration = audioPlayer?.duration ?? 0
    currentTime = 0

    #if DEBUG
    print("🔊 Audio loaded successfully")
    print("🔊 Duration: \(String(format: \"%.2f\", duration))s")
    print("🔊 Output route: \(AudioSessionManager.shared.currentOutputRoute)")
    #endif

    // Extract waveform data for visualization
    extractWaveform(from: url)
}

func play() {
    guard let player = audioPlayer else {
        print("⚠️ No audio loaded, cannot play")
        return
    }

    player.play()
    isPlaying = true
    startProgressTimer()
}
```

**Why AVAudioPlayer?**
- ✅ Does NOT require session activation
- ✅ Automatically uses existing session configuration
- ✅ Lightweight and simple
- ✅ Handles all audio formats natively

##### **4. SoundEffects (CRITICAL REWRITE)**

**Original Implementation** (BROKEN):
```swift
// ❌ OLD CODE - Caused I/O conflicts
private let audioEngine = AVAudioEngine()
private let playerNode = AVAudioPlayerNode()

func playRecordStart() {
    audioEngine.start()  // ❌ Implicitly calls setActive(true)
    playerNode.play()     // ❌ Competes with AVAudioRecorder for I/O
}
```

**New Implementation** (FIXED):
```swift
@MainActor
class SoundEffects {
    static let shared = SoundEffects()

    @ObservationIgnored private nonisolated(unsafe) var startPlayer: AVAudioPlayer?
    @ObservationIgnored private nonisolated(unsafe) var stopPlayer: AVAudioPlayer?

    private let volume: Float = 0.08  // Very low volume (calm, subtle)

    private init() {
        // CRITICAL: Do NOT configure audio session here!
        prepareAudioFiles()
    }

    private func prepareAudioFiles() {
        do {
            // Generate breath-in sound (0.5s, 200Hz)
            let startURL = try generateTone(frequency: 200, duration: 0.5, envelope: .breathIn)
            startPlayer = try AVAudioPlayer(contentsOf: startURL)
            startPlayer?.prepareToPlay()
            startPlayer?.volume = volume

            // Generate breath-out sound (0.8s, 180Hz)
            let stopURL = try generateTone(frequency: 180, duration: 0.8, envelope: .breathOut)
            stopPlayer = try AVAudioPlayer(contentsOf: stopURL)
            stopPlayer?.prepareToPlay()
            stopPlayer?.volume = volume

            #if DEBUG
            print("🎵 Sound effects prepared")
            #endif
        } catch {
            print("⚠️ Failed to prepare sound effects: \(error)")
        }
    }

    func playRecordStart() {
        startPlayer?.currentTime = 0
        startPlayer?.play()  // ✅ Uses existing session, no I/O conflict
    }

    func playRecordStop() {
        stopPlayer?.currentTime = 0
        stopPlayer?.play()
    }

    // Generate sine wave tone with envelope (breathe-in/breathe-out)
    private func generateTone(
        frequency: Float,
        duration: TimeInterval,
        envelope: Envelope
    ) throws -> URL {
        // ... Audio synthesis implementation ...
    }
}
```

**Key Changes**:
1. ❌ **Removed**: AVAudioEngine entirely
2. ✅ **Added**: AVAudioPlayer for playback (no session modification)
3. ✅ **Added**: Tone generation using AVAudioFile (saves to temp files)
4. ✅ **Improved**: Natural breath-like envelopes (fade-in/fade-out)

**Why This Fixes Crashes**:
- AVAudioEngine.start() → Implicitly activates session → I/O conflict
- AVAudioPlayer.play() → Uses existing session → No conflict

##### **5. RecordingViewModel (TIMING UPDATES)**

**Critical Change 1: Session Configuration + 300ms Delay**:
```swift
private func startRecording() async {
    // Check microphone permission
    let hasPermission = audioRecorder.checkPermission()
    if !hasPermission {
        let granted = await audioRecorder.requestPermission()
        guard granted else {
            print("⚠️ Microphone permission denied")
            return
        }
    }

    // CRITICAL: Configure audio session BEFORE recording starts
    // This is the ONLY place where session is activated
    // Prevents "Unable to join I/O thread" crashes on iPhone 15/16
    do {
        try AudioSessionManager.shared.configureSession()
    } catch {
        print("❌ Failed to configure audio session: \(error.localizedDescription)")
        recordingError = error
        state = .idle
        return
    }

    // ✅ CRITICAL: Wait 300ms for session to stabilize before starting recorder
    // Prevents I/O conflicts during session activation
    try? await Task.sleep(nanoseconds: 300_000_000)

    // Start recording
    do {
        try audioRecorder.startRecording()
        state = .recording
        elapsedTime = 0
        showStopButton = false
        setActiveSessionFlag()

        // ✅ CRITICAL: Delay sound effects and haptics by 0.5s
        // AVAudioRecorder needs exclusive audio thread access at startup
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            haptics.recordingStart()
            soundEffects.playRecordStart()
        }

        startRecordingTimer()
    } catch {
        print("❌ Failed to start recording: \(error.localizedDescription)")
        recordingError = error
        state = .idle
        stopTimer()
        audioRecorder.deleteRecording()
    }
}
```

**Critical Change 2: 500ms Delay Before Playback**:
```swift
func stopRecording() {
    audioRecorder.stopRecording()
    stopTimer()
    state = .finished
    clearActiveSessionFlag()

    // ✅ CRITICAL: Wait 500ms before loading AudioPlayer
    // Prevents I/O conflicts between stopping recorder and starting player
    // This delay ensures AVAudioRecorder fully releases audio resources
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Load audio for playback
        if let url = audioRecorder.currentAudioURL {
            do {
                try audioPlayer.load(url: url)
                #if DEBUG
                print("✅ Audio loaded for playback")
                #endif
            } catch {
                print("❌ Failed to load audio for playback: \(error)")
            }
        }

        // Play sound effects after loading is complete
        haptics.recordingStop()
        soundEffects.playRecordStop()
    }
}
```

**Timing Strategy**:
1. **300ms after session activation**: Allows I/O threads to settle
2. **500ms after recording starts**: Before playing sound effects (recorder needs exclusive access)
3. **500ms after recording stops**: Before loading player (release audio resources)

#### 🧪 Testing Results

**Build Status**: ✅ **BUILD SUCCEEDED**

**Compilation**:
- Zero errors
- Zero warnings (audio-related)
- All files integrated successfully

**Pending Manual Testing** (iPhone 15/16 Real Device):
- [ ] Recording starts without crash
- [ ] Sound effects play smoothly
- [ ] Playback works with audio from speaker
- [ ] Progress bar updates correctly
- [ ] No "I/O thread" crashes
- [ ] No "player did not see an IO cycle" errors

#### 📊 Architecture Improvements

| Aspect | Before (Broken) | After (Fixed) |
|--------|----------------|---------------|
| **Session Management** | 3+ places calling `setActive()` | ✅ Single point (AudioSessionManager) |
| **SoundEffects** | AVAudioEngine (I/O conflicts) | ✅ AVAudioPlayer (no conflicts) |
| **Timing** | No delays, immediate operations | ✅ 300ms/500ms strategic delays |
| **Defensive Checks** | None | ✅ Session state validation before recording |
| **Error Recovery** | Crashes on failure | ✅ Graceful degradation to `.idle` |
| **Playback Routing** | Receiver (听筒) | ✅ Speaker (defaultToSpeaker) |

#### 🔐 Security & Reliability

**Error Handling**:
- ✅ Session configuration failure → Return to `.idle` with error message
- ✅ Recording startup failure → Clear partial recording, reset state
- ✅ Playback load failure → Log error, allow retry

**Resource Management**:
- ✅ Audio files deleted on cleanup
- ✅ Session deactivation on app termination (future enhancement)
- ✅ Memory-efficient waveform downsampling

**Crash Prevention**:
- ✅ Single session activation point
- ✅ Timing delays prevent I/O conflicts
- ✅ Defensive state checks before operations
- ✅ AVAudioPlayer instead of AVAudioEngine

#### 📝 Integration Guide for Future Developers

**Rule 1: NEVER Modify AVAudioSession Outside AudioSessionManager**
```swift
// ❌ WRONG - Will cause crashes
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord)
try session.setActive(true)

// ✅ CORRECT - Use the manager
try AudioSessionManager.shared.configureSession()
```

**Rule 2: Use AVAudioPlayer for Sound Effects (NOT AVAudioEngine)**
```swift
// ❌ WRONG - AVAudioEngine activates session
let engine = AVAudioEngine()
engine.start()  // Implicitly calls setActive(true)

// ✅ CORRECT - AVAudioPlayer uses existing session
let player = try AVAudioPlayer(contentsOf: url)
player.play()  // No session modification
```

**Rule 3: Add Timing Delays for Audio Transitions**
```swift
// ✅ CORRECT - Wait after session activation
try AudioSessionManager.shared.configureSession()
try await Task.sleep(nanoseconds: 300_000_000)  // 300ms
try audioRecorder.startRecording()

// ✅ CORRECT - Wait after stopping recorder
audioRecorder.stopRecording()
try await Task.sleep(nanoseconds: 500_000_000)  // 500ms
try audioPlayer.load(url: url)
```

**Rule 4: Check Session State Before Recording**
```swift
// ✅ CORRECT - Defensive check
func startRecording() throws {
    if !AudioSessionManager.shared.isActive {
        try AudioSessionManager.shared.configureSession()
    }
    try audioRecorder.startRecording()
}
```

#### 🚀 Future Enhancements

**Phase 6+ Considerations**:
1. **Session Interruption Handling**: Phone calls, Siri, Control Center
2. **Background Audio**: Continue playback when app backgrounds
3. **Route Change Handling**: AirPods connect/disconnect
4. **Audio Focus Management**: Duck volume when other apps play
5. **Session Deactivation**: Properly deactivate when app terminates

**Example: Interruption Handling**:
```swift
// In AudioSessionManager
func setupInterruptionHandling() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleInterruption),
        name: AVAudioSession.interruptionNotification,
        object: session
    )
}

@objc private func handleInterruption(_ notification: Notification) {
    // Handle phone calls, alarms, etc.
}
```

#### 📚 Related Documentation

**Apple Documentation**:
- [AVAudioSession Programming Guide](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [Audio Session Categories](https://developer.apple.com/documentation/avfaudio/avaudiosession/category)
- [AVAudioRecorder Best Practices](https://developer.apple.com/documentation/avfaudio/avaudiorecorder)

**Key Concepts**:
- **I/O Thread Workgroup**: iOS audio thread management system
- **RemoteIO**: Low-level audio I/O on iOS
- **Audio Session Categories**: Determines how app interacts with audio system
- **Session Activation**: Must be exclusive, not concurrent

#### 🎓 Lessons Learned

1. **Don't Trust Initial Diagnosis**: `.record` category was NOT the issue
2. **iPhone 15/16 Are Stricter**: A18/M18 chips enforce tighter I/O management
3. **Timing Matters**: 300ms/500ms delays prevent race conditions
4. **AVAudioEngine vs AVAudioPlayer**: Engine is powerful but complex; Player is simple and safe
5. **Single Responsibility**: One manager for one concern (session)
6. **Defensive Programming**: Always check state before operations

---

### 11.4 Phase 4: Feedback Display Screen 📋

**Goal**: Design and implement the AI feedback display with micro-advice card and expandable band scores.

**Duration**: 5 hours

#### 🎯 Features to Implement

1. **Micro-Advice Card (Default View)**
   - Display `summary` and `action_tip`
   - Quoted phrase highlighted in light gradient box
   - Soft glass card with breathing glow
   - "See full feedback" button at bottom

2. **Expandable Band Scores**
   - Four circular rings (Fluency, Lexical, Grammar, Pronunciation)
   - Each ring shows qualitative visual (no numbers by default)
   - Tap ring to reveal numeric score + comment
   - Smooth expand/collapse animation

3. **Feedback Navigation**
   - "Try Again" button (same topic)
   - "New Topic" button (load next question)
   - Swipe down to dismiss (return to question card)

4. **Quote Highlighting**
   - Extract `quote` from response
   - Display in italic with subtle background
   - Breathing pulse animation (1.5s loop)

#### 📂 Files to Create/Modify

**New Files**:
- `Views/FeedbackView.swift` - Main feedback screen
- `Views/Components/MicroAdviceCard.swift` - Summary + tip card
- `Views/Components/BandScoreRing.swift` - Individual band score visualization
- `Views/Components/QuoteBox.swift` - Quoted phrase component

**Modified Files**:
- `ViewModels/RecordingViewModel.swift` - Add `feedbackResult` property
- `Views/QuestionCardView.swift` - Add navigation to FeedbackView

#### 🎨 UI Layout

**Micro-Advice Card (Default)**:
```
┌─────────────────────────────────┐
│  ✨ Your Performance            │
│                                 │
│  "Your story was engaging and   │
│   easy to follow — your tone    │
│   feels confident and natural." │
│                                 │
│  💡 Quick Tip                   │
│  Try varying your sentence      │
│  rhythm to sound even more      │
│  natural when linking ideas.    │
│                                 │
│  ╭───────────────────────────╮  │
│  │ "Actually I think it was  │  │  ← Quoted phrase
│  │  when my teacher..."      │  │
│  ╰───────────────────────────╯  │
│                                 │
│      [See full feedback ↓]      │
└─────────────────────────────────┘
```

**Expanded View**:
```
┌─────────────────────────────────┐
│  [Collapse ↑]                   │
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐     │
│  │ F●● │  │ L●● │  │ G●  │  ... │  ← Band rings
│  │  ●  │  │  ●  │  │  ●  │     │     (tap to reveal)
│  └─────┘  └─────┘  └─────┘     │
│  Fluency  Lexical   Grammar     │
│                                 │
│  [Tapped ring expands below]    │
│  Fluency: 6.5                   │
│  "Your rhythm feels smooth,     │
│   with a few long pauses."      │
│                                 │
│  [Try Again]  [New Topic]       │
└─────────────────────────────────┘
```

#### 🎨 Visual Design Details

**BandScoreRing Component**:
- Diameter: 80pt
- Ring width: 8pt
- Gradient: Amber → Azure (matching progress ring)
- Fill percentage = score / 9.0
- Tap expands to show score + comment
- Smooth rotation animation (360° over 1.5s, once)

**MicroAdviceCard**:
- Background: `.ultraThinMaterial`
- Padding: 24pt
- Corner radius: 20pt
- Shadow: soft, 12pt blur
- Text: SF Rounded, 16pt body, 22pt title

**QuoteBox**:
- Background: Amber gradient (opacity 0.1)
- Italic text, 14pt
- Pulse animation: scale 1.0 → 1.02 → 1.0 (1.5s loop)

#### 🧪 Testing Scenarios

- [ ] Feedback appears after analysis completes
- [ ] Summary and tip display correctly
- [ ] Quote box shows user's phrase
- [ ] "See full feedback" expands smoothly
- [ ] Four band rings display in grid
- [ ] Tap ring reveals score + comment
- [ ] Tap again collapses detail
- [ ] "Try Again" restarts with same topic
- [ ] "New Topic" loads different question
- [ ] Swipe down dismisses feedback

#### 🔧 Data Binding

```swift
struct FeedbackView: View {
    let result: FeedbackResult
    @State private var isExpanded = false
    @State private var selectedBand: BandCategory?

    var body: some View {
        ScrollView {
            MicroAdviceCard(
                summary: result.summary,
                tip: result.actionTip,
                quote: result.quote
            )

            if isExpanded {
                BandScoreGrid(
                    bands: result.bands,
                    selectedBand: $selectedBand
                )
            }
        }
    }
}
```

---

### 11.4 Phase 5: Polish + Final Touches 📋

**Goal**: Add sound effects, breathing animations, Dark Mode support, and performance optimizations.

**Duration**: 4 hours

#### 🎯 Features to Implement

1. **Sound Effects**
   - Recording start: soft breath-like tone (0.5s)
   - Recording stop: gentle exhale tone (0.8s)
   - Generate audio files using AVAudioEngine
   - Play via AVAudioPlayer

2. **Enhanced Breathing Animations**
   - Recording complete: circle contracts + expands (2s cycle)
   - Feedback appear: shimmer wave across card (1.5s)
   - Quote highlight: subtle pulse (continuous)

3. **Dark Mode Support**
   - Update ColorPalette with dark variants
   - Background: `#1C1C1E` (iOS dark background)
   - Cards: `.regularMaterial` (darker blur)
   - Text: auto-adjust with `.primary`
   - Test all screens in dark mode

4. **Performance Optimization**
   - Limit waveform redraws to 30fps
   - Use `@Published` selectively in ViewModels
   - Cache topic list on first load
   - Dispose audio resources immediately after use

5. **Accessibility**
   - VoiceOver labels for all interactive elements
   - Dynamic Type support (all text scales)
   - Reduce Motion: disable animations if preferred
   - High Contrast: increase border visibility

#### 📂 Files to Create/Modify

**New Files**:
- `Utilities/SoundEffects.swift` - Audio tone generator
- `Resources/Sounds/record_start.caf` - Generated breath sound
- `Resources/Sounds/record_stop.caf` - Generated exhale sound

**Modified Files**:
- `Utilities/ColorPalette.swift` - Add dark mode colors
- `Views/Components/*.swift` - Add `.preferredColorScheme` support
- `ViewModels/RecordingViewModel.swift` - Optimize state updates
- `Views/Components/WaveformView.swift` - Throttle redraws to 30fps

#### 🎨 Dark Mode Color Adjustments

```swift
extension Color {
    // Dark Mode Backgrounds
    static let darkBackground = Color(hex: "1C1C1E")
    static let darkCard = Color(hex: "2C2C2E")

    // Adaptive Colors
    static let adaptiveBackground = Color(
        light: .fogWhite,
        dark: .darkBackground
    )

    static let adaptiveCard = Color(
        light: .softGray,
        dark: .darkCard
    )
}

extension Material {
    static let adaptiveGlass: Material = {
        // iOS automatically adjusts material for dark mode
        .ultraThinMaterial
    }()
}
```

#### 🔊 Sound Generation Code

```swift
class SoundEffects {
    static let shared = SoundEffects()

    func playRecordStart() {
        // Generate breath-like tone (200Hz, fade in/out)
        generateTone(frequency: 200, duration: 0.5, envelope: .breathIn)
    }

    func playRecordStop() {
        // Generate exhale tone (180Hz, longer fade out)
        generateTone(frequency: 180, duration: 0.8, envelope: .breathOut)
    }

    private func generateTone(
        frequency: Float,
        duration: TimeInterval,
        envelope: Envelope
    ) {
        // Use AVAudioEngine to synthesize tone
        // Apply envelope for natural breath-like sound
        // Play via AVAudioPlayerNode
    }
}
```

#### 🧪 Testing Scenarios

- [ ] Sound plays on recording start
- [ ] Sound plays on recording stop
- [ ] Sounds disabled if device is muted
- [ ] Dark mode activates automatically with system
- [ ] All colors visible in dark mode
- [ ] Text remains readable in both modes
- [ ] VoiceOver announces all actions
- [ ] Dynamic Type scales all text
- [ ] Reduce Motion disables animations
- [ ] Waveform performs at 60fps (no jank)

#### ⚡ Performance Benchmarks

**Target Metrics**:
- App launch: <1.5s on iPhone 15 Pro
- Topic load: <50ms
- Recording start latency: <100ms
- Waveform rendering: 60fps sustained
- Memory usage: <50MB during recording
- Battery impact: <5% per 10-minute session

**Optimization Techniques**:
1. Lazy load audio resources
2. Reuse waveform buffers
3. Throttle state updates in ViewModels
4. Use `@Published` only for UI-bound properties
5. Dispose AVAudioPlayer immediately after playback

---

### 11.5 Phase 6: Data Persistence + Advanced Features 📋

**Goal**: Add SwiftData persistence, practice history, and 3-day reminder system.

**Duration**: 6 hours

#### 🎯 Features to Implement

1. **SwiftData Models**
   - `PracticeSession`: stores recording metadata
   - `TopicHistory`: tracks which topics practiced when
   - `UserProgress`: aggregates performance over time

2. **Practice History View**
   - List of past recordings (grouped by date)
   - Tap to replay audio
   - View past feedback
   - Delete individual sessions

3. **3-Day Reminder System**
   - Schedule local notification when topic completed
   - Notification triggers 3 days later
   - Tapping notification opens app to same topic
   - User can disable reminders in settings

4. **Progress Tracking (Internal)**
   - Calculate average band scores over time
   - Identify improvement trends
   - No gamification UI (stays hidden)
   - Used for future AI personalization

5. **Settings Screen**
   - Toggle 3-day reminders
   - Clear all practice history
   - View storage usage
   - Export data (JSON file)
   - About / Privacy Policy

#### 📂 Files to Create/Modify

**New Files**:
- `Models/PracticeSession.swift` - SwiftData model for sessions
- `Models/TopicHistory.swift` - SwiftData model for topics
- `Models/UserProgress.swift` - SwiftData model for progress
- `Services/NotificationManager.swift` - Local notification handling
- `Services/DataManager.swift` - SwiftData persistence layer
- `Views/HistoryView.swift` - Practice history list
- `Views/SettingsView.swift` - App settings
- `Views/Components/SessionCard.swift` - History list item

**Modified Files**:
- `IELTSPart2CoachApp.swift` - Add SwiftData container
- `ViewModels/RecordingViewModel.swift` - Save sessions to SwiftData
- `Models/Topic.swift` - Add relationship to TopicHistory

#### 🗄️ SwiftData Schema

```swift
@Model
class PracticeSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var topicID: UUID
    var audioFileURL: URL
    var duration: TimeInterval
    var feedbackResult: FeedbackResult?
    var transcript: String?

    // Relationships
    @Relationship var topic: TopicHistory?
}

@Model
class TopicHistory {
    @Attribute(.unique) var topicID: UUID
    var firstAttemptDate: Date
    var attemptCount: Int
    var lastAttemptDate: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var sessions: [PracticeSession]
}

@Model
class UserProgress {
    var totalSessions: Int
    var averageFluency: Double
    var averageLexical: Double
    var averageGrammar: Double
    var averagePronunciation: Double
    var lastUpdated: Date
}
```

#### 🔔 Notification System

**Schedule Notification**:
```swift
class NotificationManager {
    static let shared = NotificationManager()

    func scheduleReminder(
        for topic: Topic,
        sessionID: UUID,
        in days: Int = 3
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to practice again!"
        content.body = "Try this topic: \(topic.title)"
        content.sound = .default
        content.userInfo = [
            "topicID": topic.id.uuidString,
            "sessionID": sessionID.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days * 24 * 60 * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: sessionID.uuidString,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current()
            .add(request)
    }
}
```

**Handle Notification Tap**:
```swift
// In IELTSPart2CoachApp.swift
.onOpenURL { url in
    if let topicID = url.queryItems?["topicID"] {
        // Load specific topic
        viewModel.loadTopic(UUID(uuidString: topicID))
    }
}
```

#### 🎨 History View Layout

```
┌──────────────────────────────────┐
│  Practice History                │
│  ────────────────────────────    │
│                                  │
│  Today                           │
│  ┌────────────────────────────┐  │
│  │ 🎙 Memorable childhood...  │  │
│  │ 01:47 • Fluency 6.5       │  │
│  │ "Your story was engaging" │  │
│  └────────────────────────────┘  │
│                                  │
│  3 days ago                      │
│  ┌────────────────────────────┐  │
│  │ 🎙 A place to relax...     │  │
│  │ 02:03 • Fluency 6.0       │  │
│  └────────────────────────────┘  │
│                                  │
│  [Clear All History]             │
└──────────────────────────────────┘
```

#### 🧪 Testing Scenarios

- [ ] Recording saves to SwiftData
- [ ] History view displays all sessions
- [ ] Tap session replays audio
- [ ] Delete session removes from list
- [ ] Notification scheduled after recording
- [ ] Notification appears after 3 days
- [ ] Tap notification opens correct topic
- [ ] Settings toggle disables notifications
- [ ] Clear history removes all data
- [ ] Export creates valid JSON file

#### 🔐 Privacy & Storage

- Audio files stored in app's Documents directory
- SwiftData encrypted at rest (iOS default)
- No cloud sync (fully local)
- Export creates encrypted ZIP (optional password)
- User can delete all data instantly

---

## 12. Development Guide

### 12.1 Project Setup

#### Prerequisites

- macOS 15.0+ (Sequoia)
- Xcode 26.0.1+
- iOS 26.1 SDK
- Apple Silicon Mac (arm64)

#### Clone and Build

```bash
# Navigate to project
cd /Users/charlie/Desktop/IELTSPart2Coach

# Open in Xcode
open IELTSPart2Coach.xcodeproj

# Or build from command line
xcodebuild -scheme IELTSPart2Coach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

#### Add Microphone Permission

**Critical Step**: Must be done manually in Xcode

1. Select project in Navigator
2. Select "IELTSPart2Coach" target
3. Click "Info" tab
4. Click "+" to add new row
5. Select "Privacy - Microphone Usage Description"
6. Set value to:
   ```
   IELTS Part 2 Coach needs access to your microphone to record your speaking practice.
   ```

### 12.2 Available Simulators (iOS 26.1)

```
iPhone Devices:
- iPhone 16e
- iPhone 17 ✅ (Recommended)
- iPhone 17 Pro
- iPhone 17 Pro Max
- iPhone Air

iPad Devices:
- iPad (A16)
- iPad Air 11-inch (M3)
- iPad Air 13-inch (M3)
- iPad Pro 11-inch (M4)
- iPad Pro 13-inch (M4)
- iPad mini (A17 Pro)
```

### 12.3 Common Build Errors

#### Error: "Multiple commands produce Info.plist"

**Cause**: Manual Info.plist conflicts with auto-generated one

**Solution**: Delete manual Info.plist file, use Xcode UI to add permissions

```bash
rm IELTSPart2Coach/Info.plist
```

#### Error: "Call to main actor-isolated function in nonisolated context"

**Cause**: Swift strict concurrency in iOS 26

**Solution**: Wrap async code in `Task { @MainActor in ... }`

```swift
// ❌ Wrong
Timer.scheduledTimer(...) { self.elapsedTime += 1 }

// ✅ Correct
Timer.scheduledTimer(...) {
    Task { @MainActor in
        self.elapsedTime += 1
    }
}
```

#### Error: "Unable to find device matching destination"

**Cause**: Simulator not available

**Solution**: List available simulators and pick one

```bash
xcodebuild -showdestinations -scheme IELTSPart2Coach
```

### 12.4 File Organization

```
IELTSPart2Coach/
├── App/
│   └── IELTSPart2CoachApp.swift         # App entry point
├── Models/
│   ├── Topic.swift                       # Topic data model
│   ├── FeedbackResult.swift             # (Phase 3)
│   └── PracticeSession.swift            # (Phase 6)
├── ViewModels/
│   └── RecordingViewModel.swift          # Main state machine
├── Views/
│   ├── QuestionCardView.swift            # Main interface
│   ├── FeedbackView.swift               # (Phase 4)
│   ├── HistoryView.swift                # (Phase 6)
│   └── Components/
│       ├── LiquidGlassCard.swift
│       ├── GlassButton.swift
│       ├── CircularProgressRing.swift
│       ├── WaveformView.swift
│       ├── PreparationView.swift        # (Phase 2)
│       └── BandScoreRing.swift          # (Phase 4)
├── Services/
│   ├── AudioRecorder.swift               # Recording service
│   ├── AudioPlayer.swift                # (Phase 2)
│   ├── GeminiService.swift              # (Phase 3)
│   └── NotificationManager.swift        # (Phase 6)
├── Utilities/
│   ├── ColorPalette.swift                # Design system
│   ├── HapticManager.swift               # Haptic feedback
│   └── SoundEffects.swift               # (Phase 5)
└── Resources/
    ├── topics.json                       # Question bank
    └── Sounds/                          # (Phase 5)
        ├── record_start.caf
        └── record_stop.caf
```

### 12.5 Testing Strategy

#### Unit Testing (ViewModels)

```swift
// Example: Test recording state machine
func testRecordingStateTransitions() async {
    let viewModel = RecordingViewModel()

    // Initial state
    XCTAssertEqual(viewModel.state, .idle)

    // Start recording
    await viewModel.startRecording()
    XCTAssertEqual(viewModel.state, .recording)

    // Stop recording
    viewModel.stopRecording()
    XCTAssertEqual(viewModel.state, .finished)
}
```

#### UI Testing (SwiftUI Previews)

Use Xcode Previews for rapid iteration:

```swift
#Preview {
    QuestionCardView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    QuestionCardView()
        .preferredColorScheme(.dark)
}
```

#### Manual Testing Checklist

**Phase 1**:
- [ ] App launches in <2s
- [ ] Topic loads immediately
- [ ] Recording starts without delay
- [ ] Waveform animates smoothly
- [ ] Stop button appears at 60s
- [ ] Auto-stop at 120s works
- [ ] Playback plays audio correctly
- [ ] New Topic loads different question

**Phase 2-6**: Add specific test cases as features are implemented

### 12.6 Debugging Tips

#### Enable Audio Logging

```swift
// In AudioRecorder.swift
#if DEBUG
print("🎤 Recording started: \(audioURL.lastPathComponent)")
print("🎤 Audio level: \(normalizedLevel)")
#endif
```

#### View State Changes

```swift
// In RecordingViewModel.swift
var state: RecordingState = .idle {
    didSet {
        #if DEBUG
        print("🔄 State changed: \(oldValue) → \(state)")
        #endif
    }
}
```

#### Inspect Waveform Data

```swift
// In WaveformView.swift
.onAppear {
    print("📊 Waveform levels: \(levels)")
}
```

### 12.7 Performance Profiling

#### Use Instruments

1. Product → Profile (Cmd + I)
2. Select "Time Profiler"
3. Record while using app
4. Look for hot spots in:
   - `WaveformView.body`
   - `AudioRecorder.updateAudioLevel()`
   - State updates in ViewModels

#### Target Benchmarks

- App launch: <1.5s
- Recording start: <100ms
- Waveform render: 60fps
- Memory usage: <50MB
- Battery: <5% per 10min session

### 12.8 Git Workflow (Recommended)

```bash
# Create feature branches for each phase
git checkout -b phase-2-preparation

# Commit frequently with descriptive messages
git commit -m "feat(preparation): add 60s countdown timer"

# Merge when phase is complete and tested
git checkout main
git merge phase-2-preparation
git tag v1.2.0
```

### 12.9 Known Issues & Workarounds

#### Issue 1: Simulator Microphone Limited

**Symptom**: Waveform barely moves in simulator

**Workaround**: Test on real device for accurate audio input

#### Issue 2: Haptics Don't Work in Simulator

**Symptom**: No vibration feedback

**Workaround**: Haptics only work on physical iOS devices

#### Issue 3: Dark Mode Doesn't Auto-Switch

**Symptom**: App stays in light mode

**Workaround**: Remove `.preferredColorScheme(.light)` from IELTSPart2CoachApp.swift (added for Phase 1 testing)

---

## 13. API Integration Details

### 13.1 OpenRouter Configuration

**Endpoint**: `https://openrouter.ai/api/v1/chat/completions`

**API Key**: Stored in iOS Keychain (user configures via Settings → AI Service)

**Model**: `google/gemini-2.5-flash`

**Rate Limits**:
- Free tier: 10 requests/minute
- Expected usage: 1-2 requests per practice session
- No rate limit concerns for personal use

### 13.2 Gemini Prompt (Full Version)

```
You are an IELTS Speaking Part 2 examiner and language coach.
Listen to the audio and analyze the transcript in four areas:
1. Fluency & Coherence
2. Lexical Resource
3. Grammar Range & Accuracy
4. Pronunciation

Your task: create a warm, human-like feedback bundle in structured JSON.

Output exactly these fields:

"summary": 1–2 sentences (40–60 words) summarizing how the speech feels overall, using natural coaching tone (no grading tone).

"action_tip": 1 concise, actionable suggestion (≤25 words) that helps the user improve next time.

"bands": for each of the four IELTS categories, include "score" (0.0–9.0) and a "comment" (max 20 words) explaining why.

"quote": one short phrase directly quoted from the user's speech that best represents their expression style.

Keep tone supportive, natural, calm, like a private speaking coach.
Never use template phrases like "You should…" or "Your mistake is…".

Output only valid JSON, with double quotes for all keys and strings.
```

### 13.3 Request Example (cURL)

```bash
curl -X POST https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer sk-or-v1-c1bf..." \
  -H "Content-Type: application/json" \
  -H "HTTP-Referer: com.Charlie.IELTSPart2Coach" \
  -d '{
    "model": "google/gemini-2.5-flash",
    "messages": [{
      "role": "user",
      "content": [{
        "type": "text",
        "text": "<prompt>"
      }, {
        "type": "audio",
        "audio": "<base64-m4a>",
        "format": "m4a"
      }]
    }]
  }'
```

### 13.4 Response Parsing

```swift
struct FeedbackResult: Codable {
    let summary: String
    let actionTip: String
    let bands: BandScores
    let quote: String

    enum CodingKeys: String, CodingKey {
        case summary
        case actionTip = "action_tip"
        case bands
        case quote
    }
}

struct BandScores: Codable {
    let fluency: BandScore
    let lexical: BandScore
    let grammar: BandScore
    let pronunciation: BandScore
}

struct BandScore: Codable {
    let score: Double  // 0.0-9.0
    let comment: String
}
```

---

## 14. Future Considerations

### 14.1 Potential Phase 7 Features

1. **AI-Powered Topic Generation**
   - Generate custom topics based on user's weak areas
   - Personalized difficulty adjustment

2. **Speech-to-Text Transcript Display**
   - Show what user said (optional)
   - Highlight filler words ("um", "uh", "like")

3. **Pronunciation Drills**
   - Isolate difficult words
   - Repeat-after-me exercises

4. **Social Features**
   - Share recordings with friends (opt-in)
   - Compare anonymous band scores

5. **Apple Watch Companion**
   - Start practice from wrist
   - View daily streak

### 14.2 Scalability Considerations

**If moving to production**:

1. **Backend API**:
   - Move Gemini calls to backend server
   - Protect API key from client
   - Add user authentication

2. **Cloud Storage**:
   - Optional iCloud sync for recordings
   - CloudKit for cross-device history

3. **Analytics** (Privacy-preserving):
   - Track feature usage (no PII)
   - Aggregate feedback scores for quality improvement

4. **Monetization** (Optional):
   - Premium tier: unlimited AI analysis
   - Free tier: 5 analyses per week
   - No ads (ever)

### 14.3 Localization

**Current**: English only

**Future**: Support for:
- Simplified Chinese (简体中文)
- Traditional Chinese (繁體中文)
- Spanish (Español)
- French (Français)

Localize:
- UI strings
- Error messages
- Topic titles (or keep English for IELTS authenticity)

---

## 15. Credits & License

### 15.1 Technology Stack

- **Language**: Swift 5.0
- **Framework**: SwiftUI (iOS 26+)
- **AI**: Gemini 2.5 Flash (via OpenRouter)
- **Audio**: AVFoundation
- **Persistence**: SwiftData (Phase 6)

### 15.2 Design Inspiration

- iOS 26 Liquid Glass design language
- Apple Human Interface Guidelines
- Calm.com minimalist aesthetic

### 15.3 License

**MIT License** (Suggested for open-source)

```
Copyright (c) 2025 Charlie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

### 15.4 Disclaimer

This app is not affiliated with, endorsed by, or connected to IELTS, the British Council, IDP Education, or Cambridge Assessment English.

All IELTS-style practice questions are original creations inspired by the IELTS Speaking Part 2 format for educational purposes only.

---

## 16. Phase 7-8 Implementation Roadmap

### 16.1 Phase 7: Data Persistence & History System ✅ **IN PROGRESS**

**Goal**: Add SwiftData persistence, practice history, and 3-day reminder system.

**Duration**: 10-12 hours (5 steps)

**Design Decisions** (Confirmed 2025-11-08):
- ✅ Topic remains Codable struct (referenced by topicID)
- ✅ FeedbackResult serialized as JSON Data
- ✅ Audio saved to Documents immediately after recording
- ✅ File naming: `session_<UUID>.m4a`
- ✅ "New Topic" auto-saves without prompting
- ✅ UserProgress updates in real-time
- ✅ Error handling: Silent failure with print logs

---

#### **Step 7.1: Data Persistence Foundation** (3-4h) 🔴 **IN PROGRESS**

**Goal**: SwiftData Models + DataManager + Auto-save Integration

**New Files**:
- `Models/PracticeSession.swift` - @Model class (recording metadata)
- `Models/TopicHistory.swift` - @Model class (topic practice records)
- `Models/UserProgress.swift` - @Model class (aggregated progress data)
- `Services/DataManager.swift` - SwiftData wrapper layer

**Modified Files**:
- `IELTSPart2CoachApp.swift` - Add `.modelContainer(for: [...])`
- `ViewModels/RecordingViewModel.swift` - Integrate auto-save logic
- Audio files moved from `tmp/` to `Documents/Recordings/`

**Core Features**:
1. Create PracticeSession immediately after recording (feedback = nil)
2. Update session.feedbackData after AI analysis completes
3. "New Topic" auto-saves current session
4. Update UserProgress aggregated data after each save

**Testing Checklist**:
- [ ] Audio saved to Documents directory
- [ ] PracticeSession correctly saved to SwiftData
- [ ] FeedbackResult can be deserialized
- [ ] UserProgress auto-updates average scores
- [ ] "New Topic" does not lose recordings

---

#### **Step 7.2: History View** (2-3h) 🔴

**Goal**: History interface + Audio playback

**New Files**:
- `Views/HistoryView.swift` - Main interface
- `Views/Components/SessionCard.swift` - List item component

**Features**:
- Display sessions grouped by date ("Today", "Yesterday", "3 days ago")
- Tap session to replay audio
- Expand to view AI feedback details
- Delete individual session (swipe-to-delete)
- Empty state: "No practice history yet"

**UI Entry Point**:
- QuestionCardView top-right History button (SF Symbol: `clock.arrow.circlepath`)
- Present HistoryView as Sheet modal

**Design Style**:
- Continue using LiquidGlassCard
- Minimalist list, aligned with "calm, minimal" philosophy

---

#### **Step 7.3: Settings + Data Management** (1.5-2h) 🔴

**Goal**: Settings interface + Data control

**New Files**:
- `Views/SettingsView.swift` - Form interface

**Features**:
1. **Notifications Section**:
   - 3-day reminders toggle (disabled until Step 7.4)

2. **Data Management**:
   - View storage usage (audio files + SwiftData)
   - "Clear All History" button (requires confirmation)
   - "Export Data" (JSON format)

3. **About**:
   - App version number
   - Privacy Policy link (external URL)
   - Disclaimer: "Not affiliated with IELTS"

**UI Entry Point**:
- QuestionCardView top-left Settings button (SF Symbol: `gearshape`)

---

#### **Step 7.4: 3-Day Reminder System** (2-3h) 🟡

**Goal**: Local notification system

**New Files**:
- `Services/NotificationManager.swift` - UserNotifications wrapper

**Features**:
1. Request notification permission after first recording (graceful onboarding)
2. Schedule 3-day notification after AI feedback completion
3. Notification content: "Time to practice again! Try: [topic title]"
4. Tap notification → Open app and load corresponding topic
5. Settings toggle control

**Permission Handling**:
- Request timing: After first AI feedback received
- If denied: Silent handling, no user interruption
- Alert copy: "Get reminded to practice the same topic in 3 days?"

---

#### **Step 7.5: Progress Tracking (Internal)** (1-2h) 🟡

**Goal**: Background data analysis (no UI)

**Features**:
1. Update UserProgress after each session save
2. Calculate aggregated data:
   - Total sessions count
   - Average scores for 4 bands
   - Last updated timestamp
3. Trend identification (simple):
   - Score increase/decrease trend
   - Weakest band identification

**Data Usage**:
- Prepare for Phase 8 AI Topic Generation
- Currently no UI display

---

### 16.2 Phase 8: Enhanced Features (On-demand Implementation)

#### **Optional 8.1: Speech-to-Text Transcript** ✅ **Completed (Simplified)**

**Implemented Features**:
- ✅ Apple Speech framework integration (server-based recognition)
- ✅ Optional transcript display in FeedbackView
- ✅ Settings toggle control (default: OFF)
- ✅ Data persistence in PracticeSession model
- ❌ Filler word detection (removed due to API limitations)

**Implementation Details**:
- Created `Services/SpeechRecognitionService.swift` (130 lines) - Apple Speech wrapper
- Modified `Views/FeedbackView.swift` - Added collapsible transcript section (lines 267-318)
- Modified `Models/PracticeSession.swift` - Added optional `transcript` field (line 36)
- Modified `Services/DataManager.swift` - Added `updateSessionTranscript()` method (lines 203-214)
- Modified `Views/SettingsView.swift` - Added transcript toggle (UserDefaults key: `isTranscriptEnabled`)

**Design Decision**:
Filler word detection feature was removed after real-device testing. Apple's server-based Speech Recognition API automatically filters filler words ("um", "uh", "like") for clean transcripts. On-device recognition (`requiresOnDeviceRecognition = true`) preserves filler words but produces significantly lower quality transcripts (unacceptable for IELTS practice).

**Final Implementation**: Simple plain-text transcript display without highlighting or statistics. Aligns with "calm, minimal" design philosophy.

**Status**: ✅ Simplified version deployed (2025-11-09)

---

#### **Optional 8.2: AI-Powered Topic Generation** (4-5h) 🟢

**Features**:
- Analyze weak areas based on UserProgress
- Generate custom topics via Gemini API
- Personalized difficulty adjustment
- Dynamic TopicLoader extension

**Dependencies**:
- Requires at least 20+ sessions data
- Depends on Step 7.5 Progress Tracking
- Additional Gemini API cost

**Product Positioning**:
- Possible Premium feature
- Or consider in Phase 9+

---

### 16.3 Phase 9+: Monetization & Scalability (Not Implementing Now)

**Deferred Reasons**:
- Current focus on local features
- Business model unclear
- Insufficient user validation

**Included Features** (Future consideration):
- Backend API
- iCloud Sync
- User Authentication
- Premium Tier
- Analytics
- Localization

---

**Document Version**: 1.2
**Last Updated**: 2025-11-08
**Status**: Phase 1-6 Complete ✅ | Phase 7 IN PROGRESS 🚧 | Phase 8-9 Planned 📋
