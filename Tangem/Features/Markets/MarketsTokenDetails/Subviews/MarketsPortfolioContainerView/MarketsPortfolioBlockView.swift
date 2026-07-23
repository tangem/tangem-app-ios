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
import TangemUIUtils

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
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
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
                .fill(DesignSystem.Color.bgTertiary)
        )
    }

    private var attributedBalance: AttributedString {
        let raw = balanceText ?? BalanceFormatter().formatFiatBalance(.zero)
        var attributed = AttributedString(raw)
        attributed.font = DesignSystem.Font.bodyMediumToken.font
        attributed.foregroundColor = DesignSystem.Color.textPrimary

        let separator = Locale.current.decimalSeparator ?? "."
        if let separatorRange = attributed.range(of: separator) {
            let fractionalRange = separatorRange.lowerBound ..< attributed.endIndex
            attributed[fractionalRange].foregroundColor = DesignSystem.Color.textSecondary
        }

        return attributed
    }

    private var addFundsButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonAddFunds),
            iconStart: DesignSystem.Icons.ArrowDown.regular20,
            accessibilityLabel: Localization.commonAddFunds,
            action: onAddFundsTap
        )
        .size(.x9)
        .styleType(.secondary)
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addFundsButton)
    }

    private var expandButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.ChevronExpand.regular20,
            accessibilityLabel: nil,
            action: onExpandTap
        )
        .size(.x9)
        .styleType(.secondary)
    }
}

private extension MarketsPortfolioBlockContentView {
    enum Constants {
        static let contentSpacing: CGFloat = 8
        static let textSpacing: CGFloat = 2
        static let contentVerticalPadding: CGFloat = 12
        static let contentHorizontalPadding: CGFloat = 14
    }
}
