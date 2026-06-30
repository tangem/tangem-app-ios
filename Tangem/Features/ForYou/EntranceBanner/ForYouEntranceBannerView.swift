//
//  ForYouEntranceBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils

struct ForYouEntranceBannerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: .unit(.x3)) {
            Assets.ForYou.pieChart.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconPrimary)

            VStack(alignment: .leading, spacing: .unit(.x1)) {
                Text("For you")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Text("Review portfolio and explore earn opportunities")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.unit(.x4))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(AngularGlowBorder(config: AngularGlowBorder.Config(stopsA: Self.magicStops, stopsB: Self.magicBlendStops)))
        .clipShape(RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )
    }

    /// The glow morphs between two palettes (magic ⇄ magic-blend, ping-pong) per the v17 rig.
    /// Both share the exact Figma stop positions; only the colors differ. DS tokens are
    /// theme-dynamic, so light/dark is handled automatically.
    private static let magicStops: [Gradient.Stop] = [
        .init(color: DesignSystem.Color.glowMagicStep1, location: 0.00),
        .init(color: DesignSystem.Color.glowMagicStep2, location: 0.10),
        .init(color: DesignSystem.Color.glowMagicStep3, location: 0.25),
        .init(color: DesignSystem.Color.glowMagicStep4, location: 0.30),
        .init(color: DesignSystem.Color.glowMagicStep5, location: 0.40),
        .init(color: DesignSystem.Color.glowMagicStep6, location: 0.50),
        .init(color: DesignSystem.Color.glowMagicStep7, location: 0.60),
        .init(color: DesignSystem.Color.glowMagicStep8, location: 0.70),
        .init(color: DesignSystem.Color.glowMagicStep9, location: 0.85),
        .init(color: DesignSystem.Color.glowMagicStep10, location: 0.95),
        .init(color: DesignSystem.Color.glowMagicStep1, location: 1.00), // close the loop at the seam
    ]

    private static let magicBlendStops: [Gradient.Stop] = [
        .init(color: DesignSystem.Color.glowMagicBlendStep1, location: 0.00),
        .init(color: DesignSystem.Color.glowMagicBlendStep2, location: 0.10),
        .init(color: DesignSystem.Color.glowMagicBlendStep3, location: 0.25),
        .init(color: DesignSystem.Color.glowMagicBlendStep4, location: 0.30),
        .init(color: DesignSystem.Color.glowMagicBlendStep5, location: 0.40),
        .init(color: DesignSystem.Color.glowMagicBlendStep6, location: 0.50),
        .init(color: DesignSystem.Color.glowMagicBlendStep7, location: 0.60),
        .init(color: DesignSystem.Color.glowMagicBlendStep8, location: 0.70),
        .init(color: DesignSystem.Color.glowMagicBlendStep9, location: 0.85),
        .init(color: DesignSystem.Color.glowMagicBlendStep10, location: 0.95),
        .init(color: DesignSystem.Color.glowMagicBlendStep1, location: 1.00), // close the loop at the seam
    ]
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
        ForYouEntranceBannerView()
            .padding(.horizontal, .unit(.x4))
    }
}
#endif // DEBUG
