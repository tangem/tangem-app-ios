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
    /// Renders a portfolio row: a full-row shimmer while loading, or resolved content once available.
    struct RowView: View {
        let row: ForYouTokenRow
        var showsIndicator: Bool = false
        var isWithOverlays: Bool = true

        var body: some View {
            switch row {
            case .loading:
                LoadingRow()
            case .content(let data):
                ContentRow(data: data, showsIndicator: showsIndicator, isWithOverlays: isWithOverlays)
            }
        }
    }
}

// MARK: - Content

private extension PortfolioTokenItemView {
    struct ContentRow: View {
        let data: ForYouTokenRowData
        var showsIndicator: Bool
        var isWithOverlays: Bool

        var body: some View {
            HStack(spacing: PortfolioTokenRowLayout.horizontalSpacing) {
                TokenRowIcon(
                    iconInfo: data.tokenIconInfo,
                    showsIndicator: showsIndicator,
                    isWithOverlays: isWithOverlays
                )
                VStack(spacing: PortfolioTokenRowLayout.verticalSpacing) {
                    topLine
                    bottomLine
                }
            }
            .padding(PortfolioTokenRowLayout.contentPadding)
            // Enables `.shimmer` on the stale (cache) value; a no-op for non-cache rows.
            .environment(\.isShimmerActive, true)
        }
    }
}

private extension PortfolioTokenItemView.ContentRow {
    var topLine: some View {
        HStack(spacing: 4) {
            Text(data.symbol)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            if let sentiment = data.sentiment {
                SentimentBadge(sentiment: sentiment)
            }

            Spacer(minLength: 8)

            fiatView
        }
    }

    @ViewBuilder
    var fiatView: some View {
        switch data.end {
        case .values(let fiat, _, let source):
            HStack(spacing: 4) {
                if source == .onlyCache {
                    syncErrorIcon
                }

                Text(fiat)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .shimmer(isEnabled: source == .cache)
            }
        case .unavailable:
            Text(AppConstants.enDashSign)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
    }

    /// "Couldn't refresh, showing cached" glyph — same asset the main token list uses for this state.
    var syncErrorIcon: some View {
        Assets.failedCloud.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundStyle(DesignSystem.Color.iconTertiary)
    }

    var bottomLine: some View {
        HStack(spacing: 4) {
            subtitleView
            Spacer(minLength: 8)
            trailingContent
        }
    }

    @ViewBuilder
    var trailingContent: some View {
        switch data.end {
        case .values(_, let percent, let source):
            Text(percent)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .shimmer(isEnabled: source == .cache)
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

                DotSeparator(size: 4)

                Text(trailing)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Loading

private extension PortfolioTokenItemView {
    /// Full-row shimmer placeholder — mirrors the content row's geometry so nothing jumps on resolve.
    struct LoadingRow: View {
        @ScaledMetric private var iconSize: CGFloat = PortfolioTokenRowLayout.iconSize

        var body: some View {
            HStack(spacing: PortfolioTokenRowLayout.horizontalSpacing) {
                TangemShimmer()
                    .variant(.custom(width: iconSize, height: iconSize))
                    .clipShape(Circle())
                    .frame(width: iconSize, height: iconSize)

                VStack(spacing: PortfolioTokenRowLayout.verticalSpacing) {
                    line(leading: 96, trailing: 64, height: 14)
                    line(leading: 60, trailing: 44, height: 12)
                }
            }
            .padding(PortfolioTokenRowLayout.contentPadding)
        }
    }
}

private extension PortfolioTokenItemView.LoadingRow {
    func line(leading: CGFloat, trailing: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 4) {
            shimmer(width: leading, height: height)
            Spacer(minLength: 8)
            shimmer(width: trailing, height: height)
        }
    }

    func shimmer(width: CGFloat, height: CGFloat) -> some View {
        TangemShimmer().variant(.custom(width: width, height: height))
    }
}
