//
//  GlowRingSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum GlowRingSnapshotScenario: String, SnapshotScenario {
    case appearances
    case sizes
    case hidden

    @MainActor
    @ViewBuilder
    var body: some View {
        Group {
            switch self {
            case .appearances:
                SnapshotGrid(GlowRingAppearance.allCases, columns: 3) { appearance in
                    card(cornerRadius: 24).glowRing(appearance)
                }
            case .sizes:
                HStack(spacing: 24) {
                    card(cornerRadius: 12).glowRing(.magic, size: .card(cornerRadius: 12))
                    card(cornerRadius: 40).glowRing(.magic, size: .fullscreen(cornerRadius: 40))
                }
            case .hidden:
                card(cornerRadius: 24).glowRing(.magic, isVisible: false)
            }
        }
        .padding(16)
        .environment(\._accessibilityReduceMotion, true)
    }
}

@MainActor
private extension GlowRingSnapshotScenario {
    func card(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DesignSystem.Color.bgSecondary)
            .frame(width: 160, height: 96)
    }
}
