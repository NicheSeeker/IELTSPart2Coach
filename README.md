# IELTS Part 2 Coach

A minimalist iOS app for practicing IELTS Speaking Part 2 with AI-powered feedback.

## ✨ Features

- **🎤 Authentic IELTS Practice**: Record 2-minute responses to Part 2-style topics
- **🤖 AI-Powered Feedback**: Instant analysis from Gemini 2.5 Flash with band scores
- **📝 Speech-to-Text**: Automatic transcription of your responses (optional)
- **📊 Progress Tracking**: View practice history and monitor improvement trends
- **🎨 Beautiful Design**: Clean, distraction-free interface inspired by iOS 26 Liquid Glass
- **🔒 Privacy First**: All data stored locally, no login required

## 📱 Requirements

- iOS 26.1+
- Xcode 26.0+
- iPhone or iPad with microphone

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/NicheSeeker/IELTSPart2Coach.git
   cd IELTSPart2Coach
   ```

2. **Open in Xcode**
   ```bash
   open IELTSPart2Coach.xcodeproj
   ```

3. **Build and Run**
   - Select your iPhone or simulator as target
   - Press ⌘R to build and run
   - AI analysis requires a Cloudflare Workers backend (not included in this repo)

## 🏗️ Project Status

**Current Version**: v1.0 (App Store)

**Core Features**:
- ✅ Recording interface with real-time waveform visualization
- ✅ AI-powered feedback with Gemini 2.5 Flash (via Cloudflare Workers proxy)
- ✅ 4 IELTS band scores (Fluency, Lexical, Grammar, Pronunciation)
- ✅ Speech-to-text transcription (Apple Speech Recognition, optional)
- ✅ Practice history and progress tracking
- ✅ AI-generated topics based on weak areas
- ✅ Daily and 3-day practice reminders
- ✅ Streak tracking and retention features
- ✅ Dark mode support
- ✅ Centralized audio session management (crash-free on A18/M18 devices)

## 🎯 IELTS Band Scores

The app analyzes your speech across 4 official IELTS criteria:
- **Fluency & Coherence**: Speaking rhythm and logical flow
- **Lexical Resource**: Vocabulary range and accuracy
- **Grammar Range & Accuracy**: Sentence structures and correctness
- **Pronunciation**: Clarity and intonation

## 🔒 Privacy & Data

- ✅ All audio recordings stored locally on device
- ✅ No user accounts or login required
- ✅ No analytics or tracking
- ✅ Transcripts generated using Apple's Speech Recognition API
- ✅ AI analysis via secure backend proxy
- ✅ One-tap delete all data in Settings

## 🛠️ Tech Stack

- **Language**: Swift 5.0
- **Framework**: SwiftUI (iOS 26+)
- **Persistence**: JSON file-based (DataManager)
- **Speech Recognition**: Apple Speech Framework
- **AI Analysis**: Gemini 2.5 Flash (via OpenRouter)
- **Backend**: Cloudflare Workers (API proxy + rate limiting)
- **Audio**: AVFoundation + AudioSessionManager

## 📄 License

MIT License - See LICENSE file for details

## ⚠️ Disclaimer

This app is not affiliated with or endorsed by IELTS, the British Council, IDP Education, or Cambridge Assessment English. All practice topics are original creations for educational purposes only.

## 🙏 Acknowledgments

- Powered by [Gemini 2.5 Flash](https://deepmind.google/technologies/gemini/) for AI feedback
- Built with [Claude Code](https://claude.com/claude-code)
