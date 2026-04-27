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

struct MarketsTokenDetailsExchangeItemViewRedesign: View {
    let info: MarketsTokenDetailsExchangeItemInfo

    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var verticalPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var iconSize: CGFloat = .unit(.x9)
    @ScaledMetric private var iconCornerRadius: CGFloat = .unit(.x2)

    var body: some View {
        TangemTwoLineRowLayout(
            icon: { iconView },
            primaryLeading: {
                Text(info.name)
                    .style(Font.Tangem.Body16.semibold, color: Color.Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListExchangeName)
            },
            primaryTrailing: {
                Text(info.formattedVolume)
                    .style(Font.Tangem.Body16.semibold, color: Color.Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListTradingVolume)
            },
            secondaryLeading: {
                Text(info.exchangeType.title)
                    .style(Font.Tangem.Caption12.semibold, color: Color.Tangem.Text.Neutral.secondary)
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

#if DEBUG

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

#endif // DEBUG
