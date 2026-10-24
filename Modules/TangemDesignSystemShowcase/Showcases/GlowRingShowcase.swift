//
//  GlowRingShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GlowRingShowcase: View {
    @State private var appearance: GlowRingAppearance = .magic
    @State private var sizeOption: SizeOption = .card
    @State private var cornerRadius: CGFloat = 24
    @State private var isVisible = true

    var body: some View {
        DSShowcase("GlowRing") { controls in
            controls.picker("Appearance", $appearance)
            controls.picker("Size", $sizeOption)
            if sizeOption == .card {
                controls.value("Corner radius", $cornerRadius, in: 0 ... 60, step: 2)
            }
            controls.toggle("Visible", $isVisible)
            controls.note("magic morphs between two palettes; success, error, warning and info are static.")
        } stage: {
            banner(
                title: DSShowcaseLabel.text(appearance).capitalized,
                subtitle: "Reconfigure with the controls below",
                cornerRadius: size.cornerRadius
            )
            .glowRing(appearance, size: size, isVisible: isVisible)
            .animation(.easeInOut, value: isVisible)
        } matrix: {
            DSShowcaseGroup("Appearances") {
                DSShowcaseMatrix(rows: GlowRingAppearance.allCases) { appearance in
                    banner(
                        title: DSShowcaseLabel.text(appearance).capitalized,
                        subtitle: "\(DSShowcaseLabel.text(appearance).capitalized) glow ring",
                        cornerRadius: 24
                    )
                    .glowRing(appearance)
                    .frame(width: 300)
                    .padding(8)
                }
            }

            DSShowcaseGroup("For You banner") {
                banner(
                    title: "For You",
                    subtitle: "Review portfolio and explore earn opportunities",
                    cornerRadius: 24
                )
                .glowRing(.magic)
            }
        }
    }

    private var size: GlowRingSize {
        switch sizeOption {
        case .card: .card(cornerRadius: cornerRadius)
        case .fullscreen: .fullscreen(cornerRadius: nil)
        }
    }

    private func banner(title: String, subtitle: String, cornerRadius: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DesignSystem.Icons.PieChart.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DesignSystem.Color.bgTransparentPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
                )
        )
    }
}

private extension GlowRingShowcase {
    enum SizeOption: CaseIterable {
        case card
        case fullscreen
    }
}
#endif
