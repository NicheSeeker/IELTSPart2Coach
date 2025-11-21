//
//  APIKeySheetView.swift
//  IELTSPart2Coach
//
//  Created on 2025-11-10
//  Phase 5: API Key management sheet
//  Liquid Glass design with secure input
//

import SwiftUI

struct APIKeySheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var showPassword = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header Icon
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFC46B"), Color(hex: "9FD5FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 32)

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OpenRouter API Key")
                            .font(.system(size: 22, weight: .medium, design: .rounded))

                        Text("Get your API key from OpenRouter.ai. It's required for AI feedback analysis.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)

                        Link("Get API Key at OpenRouter.ai →", destination: URL(string: "https://openrouter.ai/keys")!)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.blue)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        if showPassword {
                            TextField("sk-or-v1-...", text: $apiKey)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-or-v1-...", text: $apiKey)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        // Show/Hide Toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPassword.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 13))
                                Text(showPassword ? "Hide" : "Show")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Security Note
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)

                        Text("Your API key is encrypted and stored securely in iOS Keychain. It never leaves your device.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.green.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Save Button
                    Button {
                        saveAPIKey()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save API Key")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFC46B"), Color(hex: "9FD5FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(apiKey.isEmpty || isSaving)
                    .opacity(apiKey.isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("API key saved successfully. You can now use AI feedback features.")
            }
            .task {
                // Load existing key if available
                do {
                    let existingKey = try KeychainManager.shared.getAPIKey()
                    apiKey = existingKey
                } catch {
                    // No existing key, start with empty field
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }

        isSaving = true

        Task { @MainActor in
            do {
                // Validate format (basic check)
                guard apiKey.hasPrefix("sk-or-v1-") else {
                    throw KeychainError.emptyKey
                }

                // Save to Keychain via GeminiService
                try GeminiService.shared.updateAPIKey(apiKey)

                // Success
                isSaving = false
                showSuccess = true

                #if DEBUG
                print("✅ API key updated via Settings UI")
                #endif
            } catch {
                // Error
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true

                #if DEBUG
                print("❌ Failed to save API key: \(error)")
                #endif
            }
        }
    }
}

#Preview {
    APIKeySheetView()
}
