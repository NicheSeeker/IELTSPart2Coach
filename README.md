# IELTS Part 2 Coach

A calm, minimalist iOS app for practicing IELTS Speaking Part 2 with AI-powered feedback.

## 🎯 Features

- **Authentic IELTS Experience**: Practice with Part 2-style topics
- **AI-Powered Feedback**: Get detailed analysis from Gemini 2.5 Flash
- **Minimalist Design**: Clean, distraction-free interface inspired by iOS 26 Liquid Glass
- **Real-time Recording**: Visual waveform feedback and smooth animations
- **Band Scores**: Receive scores across 4 IELTS criteria
  - Fluency & Coherence
  - Lexical Resource
  - Grammar Range & Accuracy
  - Pronunciation

## 📱 Requirements

- iOS 26.1+
- Xcode 26.0+
- OpenRouter API key (for Gemini access)

## 🚀 Current Status

**Phase 3 Completed** ✅
- Recording interface with 10s fast testing mode (Debug) / 60s production mode
- AI analysis integration via OpenRouter
- Basic feedback display
- Real device crash fix (API key fallback)
- Button layout optimization (2x2 grid)

**Upcoming**:
- Phase 4: Advanced feedback UI (hidden scores by default, expandable view)
- Phase 5: Polish (sound effects, dark mode, animations)
- Phase 6: Data persistence (SwiftData, practice history, 3-day reminders)

## 🛠️ Setup

1. Clone the repository
2. Open `IELTSPart2Coach.xcodeproj` in Xcode
3. Configure API key in Xcode scheme:
   - Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
   - Add: `OPENROUTER_API_KEY` = `your-key-here`
4. Select iPhone simulator or real device
5. Build and run (⌘R)

## 📖 Documentation

See `CLAUDE.md` for detailed development documentation, phase plans, and technical decisions.

## 🔒 Privacy

- All audio stored locally (no cloud uploads)
- No user tracking or analytics
- No login required
- One-tap delete all data

## 📄 License

Private repository - Not licensed for public use.

## ⚠️ Disclaimer

This app is not affiliated with or endorsed by IELTS, the British Council, IDP Education, or Cambridge Assessment English.
