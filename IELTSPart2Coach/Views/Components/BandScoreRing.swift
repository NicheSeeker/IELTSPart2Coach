//
//  BandScoreRing.swift
//  IELTSPart2Coach
//
//  Phase 4: Minimal band score ring with tap-to-reveal
//  Phase 5: Added VoiceOver accessibility support
//

import SwiftUI

struct BandScoreRing: View {
    let title: String
    let score: BandScore
    @Binding var isRevealed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景环（静态，统一青灰色）
                Circle()
                    .stroke(
                        ringColor,
                        lineWidth: 8
                    )
                    .frame(width: 80, height: 80)

                // 中心内容
                VStack(spacing: 4) {
                    if isRevealed {
                        // 数字（淡入）
                        Text(score.displayScore)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .transition(.opacity)
                    } else {
                        // 小圆点（默认状态）
                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .transition(.opacity)
                    }

                    // 标题（始终显示）
                    Text(title)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isRevealed ? 1.01 : 1.0)  // 仅 1% scale（极其微妙）
        .animation(.easeOut(duration: 0.5), value: isRevealed)
        // Phase 5: VoiceOver accessibility
        .accessibleScoreRing(
            category: title,
            score: score.score,
            comment: score.comment,
            isRevealed: isRevealed
        )
    }

    // MARK: - Computed Properties

    /// 统一青灰色调（默认 0.3 → 展开 0.6）
    private var ringColor: Color {
        isRevealed
            ? Color.secondary.opacity(0.6)  // 展开：略亮
            : Color.secondary.opacity(0.3)  // 默认：灰色
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    BandScoreRing(
        title: "Fluency",
        score: BandScore(score: 6.5, comment: "Good pacing with minor hesitations"),
        isRevealed: .constant(false),
        onTap: {}
    )
    .padding()
}

#Preview("Revealed") {
    BandScoreRing(
        title: "Pronunciation",
        score: BandScore(score: 7.0, comment: "Clear articulation"),
        isRevealed: .constant(true),
        onTap: {}
    )
    .padding()
}
