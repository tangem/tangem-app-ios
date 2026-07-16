//
//  MarketsPortfolioBlockView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct MarketsPortfolioBlockView: View {
    let state: MarketsPortfolioContainerViewModel.PortfolioBlockState
    let iconURL: URL
    let onAddTap: () -> Void
    let onAddFundsTap: () -> Void
    let onExpandTap: () -> Void

    var body: some View {
        switch state {
        case .hidden, .loading:
            EmptyView()

        case .addToken:
            AddToPortfolioPromoView(iconURL: iconURL, action: onAddTap)

        case .notSupported:
            MarketsPortfolioUnsupportedView(iconURL: iconURL)

        case .content(let data):
            MarketsPortfolioBlockContentView(
                balanceText: data.balanceText,
                onAddFundsTap: onAddFundsTap,
                onExpandTap: onExpandTap
            )
        }
    }
}

private struct MarketsPortfolioBlockContentView: View {
    let balanceText: String?
    let onAddFundsTap: () -> Void
    let onExpandTap: () -> Void

    var body: some View {
        HStack(spacing: Constants.contentSpacing) {
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                SensitiveText(attributedBalance)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(Localization.marketsPortfolioBlockSubtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.capsule)
            .onTapGesture(perform: onExpandTap)

            addFundsButton

            expandButton
        }
        .padding(.vertical, Constants.contentVerticalPadding)
        .padding(.horizontal, Constants.contentHorizontalPadding)
        .background(
            Capsule()
                .fill(Colors.Background.action)
        )
    }

    private var attributedBalance: AttributedString {
        let raw = balanceText ?? BalanceFormatter().formatFiatBalance(.zero)
        var attributed = AttributedString(raw)
        attributed.font = Fonts.Bold.body
        attributed.foregroundColor = Color.Tangem.Text.Neutral.primary

        let separator = Locale.current.decimalSeparator ?? "."
        if let separatorRange = attributed.range(of: separator) {
            let fractionalRange = separatorRange.lowerBound ..< attributed.endIndex
            attributed[fractionalRange].foregroundColor = Color.Tangem.Text.Neutral.secondary
        }

        return attributed
    }

    private var addFundsButton: some View {
        Button(action: onAddFundsTap) {
            HStack(spacing: 6) {
                DesignSystem.Icons.ArrowDown.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)

                Text(Localization.commonAddFunds)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            }
            .padding(.horizontal, Constants.actionButtonHorizontalPadding)
            .padding(.vertical, Constants.actionButtonVerticalPadding)
            .background(
                Capsule().fill(Color.Tangem.Button.backgroundSecondary)
            )
        }
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addFundsButton)
    }

    private var expandButton: some View {
        Button(action: onExpandTap) {
            Assets.arrowExpand.image
                .renderingMode(.template)
                .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
                .frame(width: Constants.expandButtonSize, height: Constants.expandButtonSize)
                .background(
                    Circle().fill(Color.Tangem.Button.backgroundSecondary)
                )
        }
    }
}

private extension MarketsPortfolioBlockContentView {
    enum Constants {
        static let contentSpacing: CGFloat = 8
        static let textSpacing: CGFloat = 2
        static let contentVerticalPadding: CGFloat = 12
        static let contentHorizontalPadding: CGFloat = 14
        static let actionButtonHorizontalPadding: CGFloat = 14
        static let actionButtonVerticalPadding: CGFloat = 8
        static let expandButtonSize: CGFloat = 36
    }
}
