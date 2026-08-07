//
//  PortfolioTokenItemView+RowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension PortfolioTokenItemView {
    struct RowView: View {
        let data: ForYouTokenRowData
        var showsIndicator: Bool = false
        /// Set only for the collapsed aggregate row, so it morphs into the expanded header.
        var effects: PortfolioTokenGeometryEffects?

        @ScaledMetric private var iconSize: CGFloat = 40

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
        }
    }
}

// MARK: - Icon

extension PortfolioTokenItemView.RowView {
    var icon: some View {
        tokenIcon
            .overlay(alignment: .bottomTrailing) {
                if showsIndicator, data.tokenIconInfo != nil {
                    indicatorDot
                }
            }
    }

    @ViewBuilder
    var tokenIcon: some View {
        if let iconInfo = data.tokenIconInfo {
            TokenIcon(
                tokenIconInfo: iconInfo,
                size: CGSize(width: iconSize, height: iconSize),
                isWithOverlays: true
            )
        } else {
            // "Other" bucket — the ds-core token placeholder glyph.
            DesignSystem.Icons.tokenError.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .matchedGeometryEffect(effects?.icon)
                .frame(width: iconSize, height: iconSize)
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
        Text(fiatText)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    var fiatText: String {
        switch data.end {
        case .values(let fiat, _):
            return fiat
        case .unavailable:
            return AppConstants.enDashSign
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

                Text(trailing)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var trailingContent: some View {
        switch data.end {
        case .values(_, let percent):
            Text(percent)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
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
                .frame(width: 16, height: 16)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }

    var dotSeparator: some View {
        Circle()
            .fill(DesignSystem.Color.iconTertiary)
            .frame(width: 4, height: 4)
    }
}
