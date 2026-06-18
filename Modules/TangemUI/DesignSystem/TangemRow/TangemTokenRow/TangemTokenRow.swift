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
    @ScaledMetric private var scaleFactor: CGFloat = 1

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
            size: CGSize(width: SizeUnit.x10.value, height: SizeUnit.x10.value) * scaleFactor
        )
        .saturation(viewData.hasMonochromeIcon ? 0 : 1)
    }

    // MARK: - Content View (switches on ContentState)

    @ViewBuilder
    private var contentView: some View {
        switch viewData.content {
        case .loading(let cached, let priceInfo):
            loadingLayout(cached: cached, priceInfo: priceInfo)
        case .loaded(let content):
            loadedLayout(content: content)
        case .error(let message):
            errorLayout(message: message)
        case .compact(let subtitle, let trailingIcon):
            compactLayout(subtitle: subtitle, trailingIcon: trailingIcon)
        }
    }

    // MARK: - Loading Layout

    private func loadingLayout(
        cached: TangemTokenRowViewData.CachedContent?,
        priceInfo: TangemTokenRowViewData.PriceInfo?
    ) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameWithBadge(isDisabled: false) },
            primaryTrailing: { fiatBalanceLoadingView(cached: cached?.fiatBalance) },
            secondaryLeading: { priceWithChangeView(priceInfo: priceInfo) },
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

    private func compactLayout(subtitle: LoadableBalanceView.State, trailingIcon: ImageType?) -> some View {
        TangemTwoLineRowLayout(
            icon: { tokenIconView },
            primaryLeading: { tokenNameView(isDisabled: false) },
            secondaryLeading: { compactSubtitleView(state: subtitle) },
            centeredTrailing: {
                if let trailingIcon {
                    trailingIcon.image
                        .renderingMode(.template)
                        .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
                }
            }
        )
        .compressionPolicy(.balanced)
    }

    private func compactSubtitleView(state: LoadableBalanceView.State) -> some View {
        LoadableBalanceView(
            state: state,
            style: LoadableBalanceView.Style(
                font: Constants.Style.TokenPrice.font,
                textColor: Constants.Style.TokenPrice.color
            ),
            loader: LoadableBalanceView.LoaderStyle(
                size: priceLoaderSize,
                cornerRadiusStyle: .capsule
            )
        )
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
            tokenPriceView(state: priceInfo?.price ?? .noData)

            priceChangeView(state: priceInfo?.change ?? .empty)
        }
        .environment(\.isShimmerActive, true)
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
                size: CGSize(width: SizeUnit.x10.value, height: SizeUnit.x3.value) * scaleFactor,
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
            .failed(cached: .string(cached))
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

    private func tokenPriceView(state: LoadableTextView.State) -> some View {
        LoadableTextView(
            state: state,
            style: Constants.Style.TokenPrice.font,
            textColor: Constants.Style.TokenPrice.color,
            loaderSize: priceLoaderSize,
            loaderCornerRadiusStyle: .capsule
        )
    }

    // MARK: - Price Change

    private func priceChangeView(state: PriceChangeView.State) -> some View {
        PriceChangeView(
            state: state,
            showSkeletonWhenLoading: true,
            showIconForNeutral: true,
            useRedesignColors: true
        )
    }

    private var cryptoLoaderSize: CGSize {
        CGSize(width: SizeUnit.x10.value, height: SizeUnit.x3.value) * scaleFactor
    }

    private var priceLoaderSize: CGSize {
        CGSize(width: SizeUnit.x13.value, height: SizeUnit.x3.value) * scaleFactor
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
