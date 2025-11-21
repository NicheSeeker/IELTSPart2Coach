//
//  ToastView.swift
//  IELTSPart2Coach
//
//  Phase 8.2: Minimal toast notification for fallback messages
//  Displays for 3 seconds at bottom of screen
//

import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Spacer()

            if isPresented {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text(message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .padding(.bottom, 60)
                .padding(.horizontal, 24)
                .transition(.opacity)
            }
        }
        .allowsHitTesting(false)  // Don't block user interaction
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        ToastView(
            message: "Using backup topic. New AI topic will appear when online.",
            isPresented: .constant(true)
        )
    }
}
