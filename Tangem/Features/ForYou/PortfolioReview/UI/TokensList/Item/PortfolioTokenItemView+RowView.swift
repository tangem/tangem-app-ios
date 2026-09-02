//
//  PortfolioTokenItemView+RowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

extension PortfolioTokenItemView {
    struct RowView: View {
        let data: ForYouTokenRowData
        /// The collapsed aggregate row (spans networks): shows the indicator dot and hides the per-network badge.
        var isAggregateRow: Bool = false
        /// Set only for the collapsed aggregate row, so it morphs into the expanded header.
        var effects: PortfolioTokenGeometryEffects?

        @ScaledMetric private var iconSize: CGFloat = 40
        @ScaledMetric private var statusIconSize: CGFloat = 16

        var body: some View {
            TangemTwoLineRowLayout(
                icon: { icon },
                primaryLeading: { symbolWithBadge },
                primaryTrailing: { fiatView },
                secondaryLeading: { subtitleView },
                secondaryTrailing: { trailingContent }
            )
            .compressionPolicy(.trailingPreserved)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .environment(\.isShimmerActive, data.freshness == .refreshing)
        }
    }
}

// MARK: - Icon

extension PortfolioTokenItemView.RowView {
    @ViewBuilder
    var icon: some View {
        if let iconInfo = data.tokenIconInfo {
            tokenIcon(iconInfo)
        } else {
            // "Other" bucket — the ds-core token placeholder glyph.
            DesignSystem.Icons.tokenError.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .matchedGeometryEffect(effects?.icon)
                .frame(width: iconSize * Metrics.placeholderGlyphScale, height: iconSize * Metrics.placeholderGlyphScale)
                .frame(width: iconSize, height: iconSize)
                .overlay(alignment: .bottomTrailing) {
                    if isAggregateRow, let indicatorColor = data.indicatorColor {
                        indicatorDot(indicatorColor)
                    }
                }
        }
    }

    func indicatorDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(size: CGSize(bothDimensions: 6))
            .padding(1)
            .background(DesignSystem.Color.bgSecondary, in: Circle())
            .offset(x: -3, y: -3)
    }

    func tokenIcon(_ iconInfo: TokenIconInfo) -> TokenIconV2 {
        var icon = TokenIconV2(tokenIconInfo: iconInfo, size: .size40)
            .geometryEffect(effects?.icon)

        if isAggregateRow, let indicatorColor = data.indicatorColor {
            icon = icon.indicatorColor(indicatorColor)
        }

        return icon
    }
}

// MARK: - Primary line

extension PortfolioTokenItemView.RowView {
    var symbolWithBadge: some View {
        HStack(spacing: 4) {
            Text(data.symbol)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(1)
                .matchedGeometryEffect(effects?.symbol)

            if let sentiment = data.sentiment {
                SentimentBadge(sentiment: sentiment)
            }
        }
    }

    var fiatView: some View {
        HStack(spacing: 4) {
            if data.freshness == .outdated {
                staleIcon
            }

            PortfolioTokenItemView.BalanceText(value: fiat)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .shimmer()
        }
    }

    var staleIcon: some View {
        DesignSystem.Icons.CloudExclamation.regular16.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: statusIconSize))
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityLabel(Localization.warningOutdatedDataTitle)
    }

    var fiat: String? {
        switch data.end {
        case .values(let fiat, _, _):
            return fiat
        case .unavailable:
            return nil
        }
    }
}

// MARK: - Secondary line

extension PortfolioTokenItemView.RowView {
    @ViewBuilder
    var subtitleView: some View {
        switch data.subtitle {
        case .text(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
        case .dotted(let leading, let trailing):
            HStack(spacing: 8) {
                Text(leading)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                dotSeparator

                PortfolioTokenItemView.BalanceText(value: trailing)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
            .shimmer()
        }
    }

    @ViewBuilder
    var trailingContent: some View {
        switch data.end {
        case .values(_, let percent, _):
            Text(percent)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .shimmer()
        case .unavailable(let label):
            warningLabel(label)
        }
    }

    func warningLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusWarning)
                .lineLimit(1)

            DesignSystem.Icons.Warning.regular16.image
                .renderingMode(.template)
                .resizable()
                .frame(size: CGSize(bothDimensions: statusIconSize))
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }

    var dotSeparator: some View {
        Circle()
            .fill(DesignSystem.Color.iconTertiary)
            .frame(width: 4, height: 4)
    }
}

// MARK: - Metrics

private extension PortfolioTokenItemView.RowView {
    enum Metrics {
        static let placeholderGlyphScale: CGFloat = 1.4
    }
}
