//
//  MarketsTokenDetailsExchangeItemViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsExchangeItemViewRedesign: View {
    let info: MarketsTokenDetailsExchangeItemInfo

    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var verticalPadding: CGFloat = 12
    @ScaledMetric private var iconSize: CGFloat = 36
    @ScaledMetric private var iconCornerRadius: CGFloat = 8

    var body: some View {
        TangemTwoLineRowLayout(
            icon: { iconView },
            primaryLeading: {
                Text(info.name)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListExchangeName)
            },
            primaryTrailing: {
                Text(info.formattedVolume)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListTradingVolume)
            },
            secondaryLeading: {
                Text(info.exchangeType.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListType)
            },
            secondaryTrailing: {
                trustScoreBadge
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListTrustScore)
            }
        )
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private var iconView: some View {
        IconView(
            url: info.iconURL,
            size: CGSize(bothDimensions: iconSize),
            cornerRadius: iconCornerRadius
        )
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListExchangeLogo)
    }

    private var trustScoreBadge: TangemBadge {
        let color: TangemBadge.BadgeColor = switch info.trustScore {
        case .trusted: .blue
        case .caution: .yellow
        case .risky: .red
        }

        return TangemBadge(text: info.trustScore.title, size: .x4)
            .color(color)
            .type(.tinted)
            .shape(.rounded)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 0) {
        MarketsTokenDetailsExchangeItemViewRedesign(info: MarketsTokenDetailsExchangeItemInfo(
            id: "btcc",
            name: "BTCC",
            trustScore: .trusted,
            exchangeType: .cex,
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW1024.png"),
            formattedVolume: "$67.52M"
        ))

        MarketsTokenDetailsExchangeItemViewRedesign(info: MarketsTokenDetailsExchangeItemInfo(
            id: "binance",
            name: "Binance",
            trustScore: .caution,
            exchangeType: .cex,
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW1024.png"),
            formattedVolume: "$67.52M"
        ))

        MarketsTokenDetailsExchangeItemViewRedesign(info: MarketsTokenDetailsExchangeItemInfo(
            id: "pionex",
            name: "Pionex",
            trustScore: .risky,
            exchangeType: .cex,
            iconURL: nil,
            formattedVolume: "$67.52M"
        ))
    }
    .padding()
}
