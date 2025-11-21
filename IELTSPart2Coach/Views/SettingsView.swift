//
//  SettingsView.swift
//  IELTSPart2Coach
//
//  Phase 7.3: Settings interface with data management
//  Calm, minimal design following Liquid Glass aesthetic
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                Form {
                    // Notifications Section (Phase 7.4 placeholder)
                    notificationsSection

                    // API Key Section (Phase 5: Keychain security)
                    apiKeySection

                    // Transcript Section (Phase 8.1)
                    transcriptSection

                    // Data Management Section
                    dataManagementSection

                    // About Section
                    aboutSection
                }
                .scrollContentBackground(.hidden) // Remove default Form background
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .task {
                await viewModel.loadStorageUsage()
            }
            .alert("Clear All History", isPresented: $viewModel.showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    Task {
                        await viewModel.clearAllHistory()
                    }
                }
            } message: {
                Text("This will permanently delete all your practice recordings and feedback. This action cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("3-Day Practice Reminders")
                        .font(.system(size: 16, weight: .regular, design: .rounded))

                    Spacer()

                    Toggle("", isOn: $notificationManager.isEnabled)
                        .labelsHidden()
                }

                // Show system permission warning if disabled
                if notificationManager.systemPermissionStatus == .denied {
                    Text("Notifications are disabled in system settings.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Notifications")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .task {
            // Update system permission status when view appears
            await notificationManager.updateSystemPermissionStatus()
        }
    }

    // MARK: - API Key Section (Phase 5)

    private var apiKeySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // API Key Status
                HStack {
                    Image(systemName: GeminiService.shared.hasAPIKey() ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(GeminiService.shared.hasAPIKey() ? .green : .orange)

                    Text(GeminiService.shared.hasAPIKey() ? "API Key Configured" : "API Key Required")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }

                // Update API Key Button
                Button {
                    viewModel.showAPIKeySheet = true
                } label: {
                    HStack {
                        Text("Update API Key")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)

                // Info Text
                Text("Your OpenRouter API key is securely stored in iOS Keychain (encrypted at rest).")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("AI Service")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .sheet(isPresented: $viewModel.showAPIKeySheet) {
            APIKeySheetView()
        }
    }

    // MARK: - Transcript Section (Phase 8.1)

    private var transcriptSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Show Transcript in Feedback")
                        .font(.system(size: 16, weight: .regular, design: .rounded))

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { UserDefaults.standard.isTranscriptEnabled },
                        set: { UserDefaults.standard.isTranscriptEnabled = $0 }
                    ))
                    .labelsHidden()
                }

                Text("See what you said in text form.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Speech Recognition")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section {
            // Storage Usage
            HStack {
                Text("Storage Usage")
                    .font(.system(size: 16, weight: .regular, design: .rounded))

                Spacer()

                if viewModel.isLoadingStorage {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.audioSizeText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Recordings")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Export Data
            Button {
                viewModel.exportData()
            } label: {
                HStack {
                    Text("Export Data")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            // Clear All History
            Button(role: .destructive) {
                viewModel.showClearConfirmation = true
            } label: {
                Text("Clear All History")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
            }
        } header: {
            Text("Data Management")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            // App Version
            HStack {
                Text("Version")
                    .font(.system(size: 16, weight: .regular, design: .rounded))

                Spacer()

                Text(Bundle.main.appVersion)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Privacy Policy
            Button {
                openPrivacyPolicy()
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            // Disclaimer
            VStack(alignment: .leading, spacing: 8) {
                Text("Disclaimer")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("This app is not affiliated with or endorsed by IELTS.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(.vertical, 4)
        } header: {
            Text("About")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }

    // MARK: - Helper Methods

    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://ieltspart2coach.com/privacy") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - SettingsViewModel

@MainActor
@Observable
class SettingsViewModel {
    var storageUsage: (audioSize: Int64, databaseSize: Int64) = (0, 0)
    var isLoadingStorage = false
    var showClearConfirmation = false
    var showShareSheet = false
    var exportedFileURL: URL?
    var showAPIKeySheet = false  // Phase 5: API key management sheet

    // MARK: - Computed Properties

    var audioSizeText: String {
        let bytes = Double(storageUsage.audioSize)

        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1_024 * 1024 {
            let kb = bytes / 1024
            return String(format: "%.1f KB", kb)
        } else if bytes < 1_024 * 1024 * 1024 {
            let mb = bytes / (1024 * 1024)
            return String(format: "%.1f MB", mb)
        } else {
            let gb = bytes / (1024 * 1024 * 1024)
            return String(format: "%.2f GB", gb)
        }
    }

    // MARK: - Data Management

    func loadStorageUsage() async {
        isLoadingStorage = true
        defer { isLoadingStorage = false }

        do {
            storageUsage = try DataManager.shared.calculateStorageUsage()

            #if DEBUG
            print("💾 Storage loaded: Audio \(audioSizeText), DB Calculating...")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load storage: \(error)")
            #endif
        }
    }

    func clearAllHistory() async {
        do {
            try DataManager.shared.clearAllData()

            // Reload storage after clearing
            await loadStorageUsage()

            #if DEBUG
            print("✅ All history cleared successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to clear history: \(error)")
            #endif
        }
    }

    func exportData() {
        do {
            // Fetch all sessions and user progress
            let sessions = try DataManager.shared.fetchAllSessions()
            let progress = try DataManager.shared.fetchUserProgress()

            // Create export data structure
            let exportData = ExportDataModel(
                appVersion: Bundle.main.appVersion,
                exportDate: Date(),
                sessions: sessions.map { SessionExport(from: $0) },
                userProgress: ProgressExport(from: progress)
            )

            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let jsonData = try encoder.encode(exportData)

            // Generate filename: IELTS_Part2_Export_yyyyMMdd_HHmmss.json
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "IELTS_Part2_Export_\(timestamp).json"

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)

            // Prepare for sharing (URL, not Data)
            exportedFileURL = tempURL
            showShareSheet = true

            #if DEBUG
            print("📦 Export prepared: \(sessions.count) sessions, \(jsonData.count) bytes")
            print("📄 File: \(fileName)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to export data: \(error)")
            #endif
        }
    }
}

// MARK: - Export Data Models

struct ExportDataModel: Codable {
    let appVersion: String
    let exportDate: Date
    let sessions: [SessionExport]
    let userProgress: ProgressExport
}

struct SessionExport: Codable {
    let id: String
    let date: Date
    let topicTitle: String
    let duration: TimeInterval
    let feedback: FeedbackExport?

    init(from session: PracticeSession) {
        self.id = session.id.uuidString
        self.date = session.date
        self.topicTitle = session.topicTitle
        self.duration = session.duration
        self.feedback = session.feedback.map { FeedbackExport(from: $0) }
    }
}

struct FeedbackExport: Codable {
    let summary: String
    let actionTip: String
    let quote: String
    let bands: BandScoresExport

    init(from feedback: FeedbackResult) {
        self.summary = feedback.summary
        self.actionTip = feedback.actionTip
        self.quote = feedback.quote
        self.bands = BandScoresExport(from: feedback.bands)
    }
}

struct BandScoresExport: Codable {
    let fluency: Double
    let lexical: Double
    let grammar: Double
    let pronunciation: Double

    init(from bands: BandScores) {
        self.fluency = bands.fluency.score
        self.lexical = bands.lexical.score
        self.grammar = bands.grammar.score
        self.pronunciation = bands.pronunciation.score
    }
}

struct ProgressExport: Codable {
    let totalSessions: Int
    let averageFluency: Double
    let averageLexical: Double
    let averageGrammar: Double
    let averagePronunciation: Double
    let lastUpdated: Date

    init(from progress: UserProgress?) {
        guard let progress = progress else {
            self.totalSessions = 0
            self.averageFluency = 0
            self.averageLexical = 0
            self.averageGrammar = 0
            self.averagePronunciation = 0
            self.lastUpdated = Date()
            return
        }

        self.totalSessions = progress.totalSessions
        self.averageFluency = progress.averageFluency
        self.averageLexical = progress.averageLexical
        self.averageGrammar = progress.averageGrammar
        self.averagePronunciation = progress.averagePronunciation
        self.lastUpdated = progress.lastUpdated
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - UserDefaults Extension (Phase 8.1: Transcript Settings)

extension UserDefaults {
    private static let transcriptEnabledKey = "isTranscriptEnabled"

    @MainActor
    var isTranscriptEnabled: Bool {
        get {
            // Default: false (disabled by default per product philosophy)
            return bool(forKey: Self.transcriptEnabledKey)
        }
        set {
            set(newValue, forKey: Self.transcriptEnabledKey)
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
