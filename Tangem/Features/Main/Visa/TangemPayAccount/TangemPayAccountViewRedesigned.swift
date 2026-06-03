//
//  TangemPayAccountViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemPay
import TangemAccessibilityIdentifiers

struct TangemPayAccountViewRedesigned: View {
    @ObservedObject var viewModel: TangemPayAccountViewModel

    var body: some View {
        TangemPayAccountTile(state: viewModel.state, onTap: viewModel.userDidTapView)
    }
}

// MARK: - Stateless tile body

private struct TangemPayAccountTile: View {
    let state: TangemPayAccountViewModel.ViewState
    let onTap: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 40
    @ScaledMetric private var cachedIconSize: CGFloat = 16
    @ScaledMetric private var cachedIndicatorSpacing: CGFloat = 6
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        Button(action: onTap) {
            content
                .padding(state.isSkeleton ? .zero : .unit(.x3))
                .background(Color.Tangem.Surface.level3)
                .cornerRadiusContinuous(.unit(.x5))
                .opacity(state.isFullyVisible ? 1 : Constants.dimmedOpacity)
        }
        .buttonStyle(.defaultScaled)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.mainScreenTile)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .skeleton:
            TangemTwoLineRowSkeletonView()

        case .normal(_, let balance, _), .cardDeactivated(let balance), .replacingCard(let balance):
            balanceRow(subtitle: state.subtitle, balance: balance, showsCachedIndicator: false)

        case .failedToIssueCard:
            stateRow(subtitle: state.subtitle, trailing: .warningIcon)

        case .kycInProgress, .kycDeclined, .issuingYourCard, .rootedDevice:
            stateRow(subtitle: state.subtitle, trailing: .none)

        case .syncNeeded(let cached), .unavailable(let cached):
            cachedStateRow(cached: cached, fallbackSubtitle: state.subtitle)
        }
    }

    // MARK: - Row variants

    private func balanceRow(
        subtitle: String,
        balance: LoadableBalanceView.State,
        showsCachedIndicator: Bool
    ) -> some View {
        TangemTwoLineRowLayout(
            icon: { visaIcon },
            primaryLeading: { titleText },
            primaryTrailing: { balanceTrailing(balance: balance, showsCachedIndicator: showsCachedIndicator) },
            secondaryLeading: { subtitleText(subtitle) },
            secondaryTrailing: { currencyText }
        )
    }

    private func stateRow(subtitle: String, trailing: TrailingAccessory) -> some View {
        TangemTwoLineRowLayout(
            icon: { visaIcon },
            primaryLeading: { titleText },
            secondaryLeading: { subtitleText(subtitle) },
            centeredTrailing: { stateTrailing(trailing) }
        )
    }

    @ViewBuilder
    private func cachedStateRow(
        cached: TangemPayAccountViewModel.CachedDisplayData?,
        fallbackSubtitle: String
    ) -> some View {
        if let cached {
            let resolvedSubtitle = cached.subtitle ?? fallbackSubtitle
            switch cached.trailing {
            case .balance(let balance):
                balanceRow(subtitle: resolvedSubtitle, balance: balance, showsCachedIndicator: true)
            case .warningIcon:
                stateRow(subtitle: resolvedSubtitle, trailing: .warningIcon)
            case .empty:
                stateRow(subtitle: resolvedSubtitle, trailing: .cachedCloud)
            }
        } else {
            stateRow(subtitle: fallbackSubtitle, trailing: .none)
        }
    }

    // MARK: - Shared elements

    private var visaIcon: some View {
        Assets.Visa.accountAvatar.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
    }

    private var titleText: some View {
        Text(Localization.tangempayPaymentAccount)
            .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
            .lineLimit(1)
    }

    private func subtitleText(_ text: String) -> some View {
        Text(text)
            .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
            .lineLimit(1)
    }

    private func balanceTrailing(balance: LoadableBalanceView.State, showsCachedIndicator: Bool) -> some View {
        HStack(spacing: cachedIndicatorSpacing) {
            if showsCachedIndicator {
                cachedCloudIcon
            }

            LoadableBalanceView(
                state: TangemPayAccountTile.applyDecimalColoring(balance),
                style: LoadableBalanceView.Style(
                    font: TangemPayAccountTile.balanceFont,
                    textColor: TangemPayAccountTile.balanceIntegerColor
                ),
                loader: LoadableBalanceView.LoaderStyle(
                    size: CGSize(width: 40, height: 12) * scaleFactor,
                    cornerRadiusStyle: .capsule
                )
            )
        }
    }

    private var currencyText: some View {
        SensitiveText(TangemPayUtilities.usdcTokenItem.currencySymbol)
            .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
    }

    @ViewBuilder
    private func stateTrailing(_ trailing: TrailingAccessory) -> some View {
        switch trailing {
        case .none:
            EmptyView()
        case .warningIcon:
            Assets.redCircleWarning.image
        case .cachedCloud:
            cachedCloudIcon
        }
    }

    private var cachedCloudIcon: some View {
        Assets.failedCloud.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)
            .frame(width: cachedIconSize, height: cachedIconSize)
    }
}

// MARK: - Nested types

private extension TangemPayAccountTile {
    enum TrailingAccessory {
        case none
        case warningIcon
        case cachedCloud
    }

    enum Constants {
        static let dimmedOpacity: Double = 0.6
    }

    static let balanceFont: Font = TangemRowConstants.Style.Title.font
    static let balanceIntegerColor: Color = .Tangem.Text.Neutral.primary
    static let balanceDecimalColor: Color = .Tangem.Text.Neutral.secondary

    static func applyDecimalColoring(_ state: LoadableBalanceView.State) -> LoadableBalanceView.State {
        switch state {
        case .loaded(let text):
            return .loaded(text: recolor(text))
        case .loading(let cached):
            return .loading(cached: cached.map(recolor))
        case .failed(let cached, let icon):
            return .failed(cached: recolor(cached), icon: icon)
        }
    }

    private static func recolor(_ text: LoadableBalanceView.Text) -> LoadableBalanceView.Text {
        switch text {
        case .string(let raw):
            return .attributed(format(raw))
        case .attributed, .builder:
            return text
        }
    }

    private static func format(_ raw: String) -> AttributedString {
        TangemTokenRowBalanceFormatter.formatWithDecimalColoring(
            raw,
            font: balanceFont,
            integerColor: balanceIntegerColor,
            decimalColor: balanceDecimalColor
        )
    }
}
