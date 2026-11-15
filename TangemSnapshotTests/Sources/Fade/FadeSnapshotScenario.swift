//
//  FadeSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI
import TangemUIUtils

enum FadeSnapshotScenario: String, SnapshotScenario {
    case variants
    case blurred
    case backgroundColor
    case feedTopFade

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .variants:
            SnapshotGrid(variantCases, columns: 4) { sample in
                fadedContent(position: sample.position) {
                    Fade(position: sample.position).variant(sample.variant)
                }
            }
        case .blurred:
            SnapshotGrid(variantCases, columns: 4) { sample in
                fadedContent(position: sample.position) {
                    Fade(position: sample.position).variant(sample.variant).blurred()
                }
            }
        case .backgroundColor:
            SnapshotGrid(variantCases, columns: 4) { sample in
                fadedContent(position: sample.position, background: DesignSystem.Color.bgBrand) {
                    Fade(position: sample.position)
                        .variant(sample.variant)
                        .backgroundColor(DesignSystem.Color.bgBrand)
                }
            }
        case .feedTopFade:
            content
                .reverseMask(alignment: .top) { FeedTopFade() }
        }
    }
}

@MainActor
private extension FadeSnapshotScenario {
    var variantCases: [(position: Fade.Position, variant: Fade.Variant)] {
        Fade.Position.allCases.flatMap { position in
            Fade.Variant.allCases.map { (position, $0) }
        }
    }

    func fadedContent(
        position: Fade.Position,
        background: Color = DesignSystem.Color.bgPrimary,
        @ViewBuilder fade: () -> some View
    ) -> some View {
        content
            .background(background)
            .overlay(alignment: position == .top ? .top : .bottom) {
                fade().frame(height: 120)
            }
    }

    var content: some View {
        VStack(spacing: 0) {
            ForEach(1 ... 8, id: \.self) { index in
                Text("Row \(index)")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 25)
                    .background(index.isMultiple(of: 2) ? DesignSystem.Color.bgSecondary : DesignSystem.Color.bgInverse.opacity(0.1))
            }
        }
        .frame(width: 140, height: 200)
    }
}
