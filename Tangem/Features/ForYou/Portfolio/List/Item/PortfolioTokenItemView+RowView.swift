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

        var body: some View {
            HStack(spacing: 12) {
                TokenRowIcon(
                    iconInfo: data.tokenIconInfo,
                    isLoading: data.isLoading,
                    showsIndicator: showsIndicator
                )
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
                    SentimentBadge(sentiment: sentiment)
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

    func shimmer(width: CGFloat, height: CGFloat) -> some View {
        TangemShimmer().variant(.custom(width: width, height: height))
    }
}
