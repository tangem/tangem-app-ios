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
            TokenIcon(
                tokenIconInfo: iconInfo,
                size: CGSize(width: size, height: size),
                isWithOverlays: true
            )
        } else {
            // "Other" bucket — the empty-currency glyph.
            Assets.emptyTokenList.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: size, height: size)
        }
    }

    // [REDACTED_TODO_COMMENT]
    var indicatorDot: some View {
        Circle()
            .fill(DesignSystem.Color.iconAccentRed)
            .frame(width: 4, height: 4)
            .padding(1)
            .background(DesignSystem.Color.bgSecondary, in: Circle())
            .offset(x: -3, y: -3)
    }
}
