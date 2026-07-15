//
//  TokenRowIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TokenRowIcon: View {
    let iconInfo: TokenIconInfo?
    var showsIndicator: Bool = false

    @ScaledMetric private var size: CGFloat = 40

    var body: some View {
        content
            .overlay(alignment: .bottomTrailing) {
                // No indicator on the empty-icon "Other" bucket.
                if showsIndicator, iconInfo != nil {
                    indicatorDot
                }
            }
    }
}

private extension TokenRowIcon {
    @ViewBuilder
    var content: some View {
        if let iconInfo {
            // Overlays on: the per-network glyph shows for child rows (their info carries a network
            // asset); aggregate rows carry a nil asset, so no glyph appears.
            TokenIcon(
                tokenIconInfo: iconInfo,
                size: CGSize(width: size, height: size),
                isWithOverlays: true
            )
        } else {
            // "Other" bucket — the empty-currency glyph (equivalent of the empty icon state).
            Assets.emptyTokenList.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: size, height: size)
        }
    }

    /// [REDACTED_TODO_COMMENT]
    /// per-network indicator comes with the data pipeline. Ring uses the card fill so it "punches out".
    var indicatorDot: some View {
        Circle()
            .fill(DesignSystem.Color.iconAccentRed)
            .frame(width: 4, height: 4)
            .padding(1)
            .background(DesignSystem.Color.bgSecondary, in: Circle())
            .offset(x: -3, y: -3)
    }
}
