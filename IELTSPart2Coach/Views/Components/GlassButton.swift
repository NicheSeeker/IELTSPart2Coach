//
//  GlassButton.swift
//  IELTSPart2Coach
//
//  Interactive button with Liquid Glass styling
//  Features: gradient overlay, haptic feedback, smooth animations
//

import SwiftUI

struct GlassButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary    // Amber to Azure gradient
        case secondary  // Subtle glass effect
        case minimal    // Text only with glass background

        var showGradient: Bool {
            self == .primary
        }
    }

    init(
        _ title: String,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(style.showGradient ? .white : .primary)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(minWidth: 120)
                .background {
                    ZStack {
                        // Glass base
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)

                        // Gradient overlay for primary style
                        if style.showGradient {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.linearGradient(
                                    colors: [.amber, .azure],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        }

                        // Highlight overlay
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Border
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                style.showGradient
                                    ? Color.white.opacity(0.3)
                                    : Color.primary.opacity(0.1),
                                lineWidth: 1
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Custom Button Style

private struct PressableButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.fogWhite
            .ignoresSafeArea()

        VStack(spacing: 24) {
            GlassButton("Start Recording", style: .primary) {
                print("Primary tapped")
            }

            GlassButton("Secondary", style: .secondary) {
                print("Secondary tapped")
            }

            GlassButton("Minimal", style: .minimal) {
                print("Minimal tapped")
            }
        }
    }
}
