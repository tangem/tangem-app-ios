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

        @ScaledMetric private var iconSize: CGFloat = 40

        var body: some View {
            HStack(spacing: 12) {
                icon
                VStack(spacing: 4) {
                    topLine
                    bottomLine
                }
            }
        }
    }
}

extension PortfolioTokenItemView.RowView {
    // MARK: - Lines

    var topLine: some View {
        HStack(spacing: 4) {
            if data.isLoading {
                shimmer(width: 96, height: 14)
                Spacer(minLength: 8)
                shimmer(width: 64, height: 14)
            } else {
                Text(data.symbol)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                if let sentiment = data.sentiment {
                    sentimentBadge(sentiment)
                }

                Spacer(minLength: 8)

                Text(fiatText)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    var fiatText: String {
        switch data.end {
        case .values(let fiat, _):
            return fiat
        case .unavailable:
            return AppConstants.enDashSign
        }
    }

    var bottomLine: some View {
        HStack(spacing: 4) {
            if data.isLoading {
                shimmer(width: 60, height: 12)
                Spacer(minLength: 8)
                shimmer(width: 44, height: 12)
            } else {
                subtitleView

                Spacer(minLength: 8)

                trailingContent
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

                Circle()
                    .fill(DesignSystem.Color.iconTertiary)
                    .frame(width: 4, height: 4)

                Text(trailing)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Icon

    var icon: some View {
        iconContent
            .overlay(alignment: .bottomTrailing) {
                // No indicator on the empty-icon "Other" bucket.
                if showsIndicator, !data.isLoading, data.tokenIconInfo != nil {
                    indicatorDot
                }
            }
    }

    @ViewBuilder
    var iconContent: some View {
        if data.isLoading {
            TangemShimmer()
                .variant(.custom(width: iconSize, height: iconSize))
                .clipShape(Circle())
                .frame(width: iconSize, height: iconSize)
        } else if let tokenIconInfo = data.tokenIconInfo {
            // Overlays on: the per-network glyph shows for child rows (their info carries a network
            // asset); aggregate rows carry a nil asset, so no glyph appears.
            TokenIcon(
                tokenIconInfo: tokenIconInfo,
                size: CGSize(width: iconSize, height: iconSize),
                isWithOverlays: true
            )
        } else {
            // "Other" bucket — the empty-currency glyph (equivalent of the empty icon state).
            Assets.emptyTokenList.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: iconSize, height: iconSize)
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

    // MARK: - Sentiment badge

    /// Placeholder price-change badge; real sentiment data lands with the price-change pipeline.
    func sentimentBadge(_ sentiment: ForYouTokenRowData.Sentiment) -> some View {
        let colors = sentimentColors(sentiment)
        return Text(sentimentTitle(sentiment))
            .style(DesignSystem.Font.captionMediumToken, color: colors.foreground)
            .padding(.horizontal, 4)
            .frame(minHeight: 16)
            .background(colors.background)
            .clipShape(Capsule())
    }

    func sentimentTitle(_ sentiment: ForYouTokenRowData.Sentiment) -> String {
        switch sentiment {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        }
    }

    func sentimentColors(_ sentiment: ForYouTokenRowData.Sentiment) -> (foreground: Color, background: Color) {
        switch sentiment {
        case .negative:
            return (DesignSystem.Color.textStatusError, DesignSystem.Color.bgStatusErrorSubtle)
        case .neutral:
            return (DesignSystem.Color.textStatusInfo, DesignSystem.Color.bgStatusInfoSubtle)
        case .positive:
            return (DesignSystem.Color.textStatusSuccess, DesignSystem.Color.bgStatusSuccessSubtle)
        }
    }

    func shimmer(width: CGFloat, height: CGFloat) -> some View {
        TangemShimmer().variant(.custom(width: width, height: height))
    }
}

// MARK: - Previews

#Preview {
    func icon(_ id: String, network: ImageType? = nil) -> TokenIconInfo {
        TokenIconInfo(
            name: "",
            blockchainIconAsset: network,
            imageURL: IconURLBuilder().tokenIconURL(id: id),
            isCustom: false,
            customTokenColor: nil
        )
    }

    return VStack(spacing: 8) {
        PortfolioTokenItemView.RowView(data: ForYouTokenRowData(
            id: "btc",
            isLoading: false,
            symbol: "Bitcoin",
            tokenIconInfo: icon("bitcoin"),
            sentiment: .positive,
            subtitle: .text("Main network"),
            end: .values(fiat: "$849", percent: "8.49%")
        ))
        PortfolioTokenItemView.RowView(data: ForYouTokenRowData(
            id: "sol",
            isLoading: false,
            symbol: "Solana",
            tokenIconInfo: icon("solana", network: Tokens.solanaFill),
            sentiment: .neutral,
            subtitle: .dotted("Solana", "6.2 SOL"),
            end: .values(fiat: "$700", percent: "7.0%")
        ))
        PortfolioTokenItemView.RowView(data: ForYouTokenRowData(
            id: "eth",
            isLoading: false,
            symbol: "Ethereum",
            tokenIconInfo: icon("ethereum"),
            sentiment: nil,
            subtitle: .text("Ethereum"),
            end: .unavailable(label: "Unreachable")
        ))
        PortfolioTokenItemView.RowView(data: ForYouTokenRowData(
            id: "atom",
            isLoading: false,
            symbol: "Cosmos",
            tokenIconInfo: icon("cosmos"),
            sentiment: nil,
            subtitle: .dotted("Cosmos", "–"),
            end: .unavailable(label: "No address")
        ))
        PortfolioTokenItemView.RowView(data: .loading(id: "l"))
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
