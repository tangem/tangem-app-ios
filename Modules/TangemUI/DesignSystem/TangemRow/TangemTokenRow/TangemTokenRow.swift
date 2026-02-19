//
//  TangemTokenRow.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUIUtils

public struct TangemTokenRow: View {
    private typealias Constants = TangemTokenRowConstants
    private typealias RowConstants = TangemRowConstants

    private let viewData: TangemTokenRowViewData

    @ScaledMetric private var priceChangeIconSpacing: CGFloat = TangemTokenRowConstants.Spacings.priceChangeIconSpacing

    @ScaledSize private var fiatLoaderSize: CGSize = TangemTokenRowConstants.Sizes.fiatBalanceLoaderSize
    @ScaledSize private var cryptoLoaderSize: CGSize = TangemTokenRowConstants.Sizes.cryptoBalanceLoaderSize
    @ScaledSize private var priceLoaderSize: CGSize = TangemTokenRowConstants.Sizes.tokenPriceLoaderSize
    @ScaledSize private var iconSize = CGSize(width: Constants.Sizes.iconSize, height: Constants.Sizes.iconSize)

    public init(viewData: TangemTokenRowViewData) {
        self.viewData = viewData
    }

    public var body: some View {
        contentView
    }

    // MARK: - Token Icon

    private var tokenIconView: some View {
        TokenIcon(
            tokenIconInfo: viewData.tokenIconInfo,
            size: iconSize
        )
        .saturation(viewData.hasMonochromeIcon ? 0 : 1)
    }

    // MARK: - Content View (switches on ContentState)

    @ViewBuilder
    private var contentView: some View {
        switch viewData.content {
        case .loading(let cached):
            loadingLayout(cached: cached)
        case .loaded(let content):
            loadedLayout(content: content)
        case .error(let message):
            errorLayout(message: message)
        case .compact(let price):
            compactLayout(price: price)
        }
    }

    // MARK: - Loading Layout

    private func loadingLayout(cached: TangemTokenRowViewData.CachedContent?) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameWithBadge(isDisabled: false) },
            primaryTrailing: { fiatBalanceLoadingView(cached: cached?.fiatBalance) },
            secondaryLeading: { tokenPriceLoadingView(cached: cached?.price) },
            secondaryTrailing: { cryptoBalanceLoadingView(cached: cached?.cryptoBalance) }
        )
        .compressionPolicy(.trailingPreserved)
    }

    // MARK: - Loaded Layout

    private func loadedLayout(content: TangemTokenRowViewData.LoadedContent) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameWithBadge(isDisabled: content.balances.fiat.isFailed) },
            primaryTrailing: { fiatBalanceValueView(value: content.balances.fiat) },
            secondaryLeading: { priceWithChangeView(priceInfo: content.priceInfo) },
            secondaryTrailing: { cryptoBalanceView(value: content.balances.crypto) }
        )
        .compressionPolicy(.trailingPreserved)
    }

    // MARK: - Error Layout

    private func errorLayout(message: String) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameView(isDisabled: true) },
            primaryTrailing: {
                Text(message)
                    .style(Constants.Style.FiatBalance.font, color: Constants.Style.TokenName.disabledColor)
                    .lineLimit(1)
            },
            secondaryLeading: {
                // Hidden placeholder to maintain consistent row height
                Text(" ")
                    .style(Constants.Style.TokenPrice.font, color: .clear)
            },
            secondaryTrailing: { EmptyView() }
        )
        .compressionPolicy(.custom(TangemRowCompressionPriorities(
            primaryLeading: 1,
            primaryTrailing: 2,
            secondaryLeading: 1,
            secondaryTrailing: 1
        )))
    }

    // MARK: - Compact Layout

    private func compactLayout(price: String?) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameView(isDisabled: false) },
            primaryTrailing: { EmptyView() },
            secondaryLeading: {
                if let price {
                    Text(price)
                        .style(Constants.Style.TokenPrice.font, color: Constants.Style.TokenPrice.color)
                        .lineLimit(1)
                } else {
                    styledDashText
                }
            },
            secondaryTrailing: { EmptyView() }
        )
        .compressionPolicy(.balanced)
    }

    // MARK: - Token Name With Badge

    private func tokenNameWithBadge(isDisabled: Bool) -> some View {
        HStack(spacing: Constants.Spacings.badgeSpacing) {
            tokenNameView(isDisabled: isDisabled)

            badgeView
        }
    }

    // MARK: - Price With Change

    private func priceWithChangeView(priceInfo: TangemTokenRowViewData.PriceInfo?) -> some View {
        HStack(spacing: Constants.Spacings.badgeSpacing) {
            tokenPriceView(priceInfo: priceInfo)

            priceChangeView(priceInfo: priceInfo)
        }
    }

    // MARK: - Token Name

    private func tokenNameView(isDisabled: Bool) -> some View {
        Text(viewData.name)
            .style(
                RowConstants.Style.Title.font,
                color: isDisabled ? Constants.Style.TokenName.disabledColor : RowConstants.Style.Title.color
            )
            .lineLimit(1)
            .accessibilityIdentifier(viewData.accessibilityIdentifiers?.tokenName)
    }

    // MARK: - Badge

    @ViewBuilder
    private var badgeView: some View {
        switch viewData.badge {
        case .pendingTransaction:
            pendingTransactionBadge
        case .rewards(let info):
            rewardsBadge(info: info)
        case .none:
            EmptyView()
        }
    }

    private var pendingTransactionBadge: some View {
        // [REDACTED_TODO_COMMENT]
        // but currently it is static asset in figma file
        ProgressDots(style: .small)
    }

    private func rewardsBadge(info: TangemTokenRowViewData.RewardsInfo) -> some View {
        TangemBadge(text: info.value, size: .x4)
            .type(.tinted)
            .color(info.isActive ? .blue : .gray)
            .shimmer()
            .environment(\.isShimmerActive, info.isUpdating)
            .accessibilityIdentifier(viewData.accessibilityIdentifiers?.rewardsBadge)
    }

    // MARK: - Fiat Balance

    private func formattedFiatBalance(_ text: String) -> AttributedString {
        TangemTokenRowBalanceFormatter.formatWithDecimalColoring(
            text,
            font: Constants.Style.FiatBalance.font,
            integerColor: Constants.Style.FiatBalance.integerColor,
            decimalColor: Constants.Style.FiatBalance.decimalColor
        )
    }

    private func fiatBalanceView(state: LoadableBalanceView.State) -> some View {
        LoadableBalanceView(
            state: state,
            style: .init(
                font: Constants.Style.FiatBalance.font,
                textColor: Constants.Style.FiatBalance.integerColor
            ),
            loader: .init(
                size: fiatLoaderSize,
                cornerRadiusStyle: .capsule
            ),
            accessibilityIdentifier: viewData.accessibilityIdentifiers?.fiatBalance
        )
    }

    @ViewBuilder
    private func fiatBalanceLoadingView(cached: String?) -> some View {
        let state: LoadableBalanceView.State = if let cached {
            .loading(cached: .attributed(formattedFiatBalance(cached)))
        } else {
            .loading(cached: nil)
        }

        fiatBalanceView(state: state)
    }

    @ViewBuilder
    private func fiatBalanceValueView(value: TangemTokenRowViewData.BalanceValue) -> some View {
        let state: LoadableBalanceView.State = switch value {
        case .value(let text):
            .loaded(text: .attributed(formattedFiatBalance(text)))
        case .failed(let cached):
            .failed(cached: .attributed(formattedFiatBalance(cached)), icon: .leading)
        }
        fiatBalanceView(state: state)
    }

    // MARK: - Crypto Balance

    @ViewBuilder
    private func cryptoBalanceLoadingView(cached: String?) -> some View {
        LoadableBalanceView(
            state: .loading(cached: cached.map { .string($0) }),
            style: .init(
                font: Constants.Style.CryptoBalance.font,
                textColor: Constants.Style.CryptoBalance.color
            ),
            loader: .init(
                size: cryptoLoaderSize,
                cornerRadiusStyle: .capsule
            ),
            accessibilityIdentifier: viewData.accessibilityIdentifiers?.cryptoBalance
        )
    }

    private func cryptoBalanceView(value: TangemTokenRowViewData.BalanceValue) -> some View {
        let state: LoadableBalanceView.State = switch value {
        case .value(let text):
            .loaded(text: .string(text))
        case .failed(let cached):
            .failed(cached: .string(cached), icon: .trailing)
        }

        return LoadableBalanceView(
            state: state,
            style: .init(
                font: Constants.Style.CryptoBalance.font,
                textColor: Constants.Style.CryptoBalance.color
            ),
            loader: .init(
                size: cryptoLoaderSize,
                cornerRadiusStyle: .capsule
            ),
            accessibilityIdentifier: viewData.accessibilityIdentifiers?.cryptoBalance
        )
    }

    // MARK: - Token Price

    private func tokenPriceLoadingView(cached: String?) -> some View {
        let state: LoadableTextView.State = if let cached {
            .loaded(text: cached)
        } else {
            .loading
        }

        return LoadableTextView(
            state: state,
            font: Constants.Style.TokenPrice.font,
            textColor: Constants.Style.TokenPrice.color,
            loaderSize: priceLoaderSize,
            loaderCornerRadiusStyle: .capsule
        )
    }

    private func tokenPriceView(priceInfo: TangemTokenRowViewData.PriceInfo?) -> some View {
        let state: LoadableTextView.State = if let priceInfo {
            .loaded(text: priceInfo.price)
        } else {
            .noData
        }

        return LoadableTextView(
            state: state,
            font: Constants.Style.TokenPrice.font,
            textColor: Constants.Style.TokenPrice.color,
            loaderSize: priceLoaderSize,
            loaderCornerRadiusStyle: .capsule
        )
    }

    private var styledDashText: some View {
        Text(verbatim: .enDashSign)
            .style(Constants.Style.TokenPrice.font, color: Constants.Style.TokenPrice.color)
            .lineLimit(1)
    }

    // MARK: - Price Change

    @ViewBuilder
    private func priceChangeView(priceInfo: TangemTokenRowViewData.PriceInfo?) -> some View {
        if let change = priceInfo?.change {
            PriceChangeView(
                state: .loaded(changeType: change.type, text: change.text),
                showSkeletonWhenLoading: false,
                showIconForNeutral: true
            )
        }
    }
}

// MARK: - BalanceValue Helpers

private extension TangemTokenRowViewData.BalanceValue {
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

// MARK: Look for previews in `TangemTokenRowPreviews` file
