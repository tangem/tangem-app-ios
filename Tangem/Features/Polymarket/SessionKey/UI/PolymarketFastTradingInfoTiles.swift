//
//  PolymarketFastTradingInfoTiles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketFastTradingInfoTiles: View {
    let onDurationInfo: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        layout {
            durationTile

            tile(
                caption: PolymarketFastTradingStrings.nameCaption,
                value: PolymarketFastTradingStrings.nameValue,
                showsInfo: false
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }

    private var layout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(spacing: Constants.tileSpacing))
        } else {
            AnyLayout(HStackLayout(alignment: .top, spacing: Constants.tileSpacing))
        }
    }

    @ViewBuilder
    private var durationTile: some View {
        let tile = tile(
            caption: PolymarketFastTradingStrings.durationCaption,
            value: PolymarketFastTradingStrings.durationValue,
            showsInfo: onDurationInfo != nil
        )

        if let onDurationInfo {
            SwiftUI.Button(action: onDurationInfo) { tile }
                .buttonStyle(.plain)
                .accessibilityHint(PolymarketFastTradingStrings.whatIsFastTrading)
        } else {
            tile
        }
    }

    private func tile(caption: String, value: String, showsInfo: Bool) -> some View {
        VStack(alignment: .leading, spacing: Constants.tileTextSpacing) {
            HStack(spacing: Constants.tileCaptionSpacing) {
                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                if showsInfo {
                    DesignSystem.Icons.Info.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                        .accessibilityHidden(true)
                }
            }

            Text(value)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Constants.tilePadding)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.tileCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private enum Constants {
    static let horizontalPadding: CGFloat = 24
    static let verticalPadding: CGFloat = 12
    static let tileSpacing: CGFloat = 8
    static let tileTextSpacing: CGFloat = 8
    static let tileCaptionSpacing: CGFloat = 2
    static let tilePadding: CGFloat = 16
    static let tileCornerRadius: CGFloat = 24
}
