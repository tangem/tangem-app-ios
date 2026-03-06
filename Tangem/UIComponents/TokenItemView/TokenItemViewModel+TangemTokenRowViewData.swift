//
//  TokenItemViewModel+TangemTokenRowViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension TokenItemViewModel {
    var tokenRowViewData: TangemTokenRowViewData {
        TangemTokenRowViewData(
            id: id,
            tokenIconInfo: TokenIconInfo(
                name: name,
                blockchainIconAsset: blockchainIconAsset,
                imageURL: imageURL,
                isCustom: isCustom,
                customTokenColor: customTokenColor
            ),
            name: name,
            badge: badgeViewData,
            content: contentState,
            hasMonochromeIcon: hasMonochromeIcon
        )
    }
}

// MARK: - Private

private extension TokenItemViewModel {
    var badgeViewData: TangemTokenRowViewData.Badge? {
        switch leadingBadge {
        case .pendingTransaction:
            .pendingTransaction

        case .rewards(let info):
            .rewards(
                TangemTokenRowViewData.RewardsInfo(
                    value: info.rewardValue,
                    isActive: info.isActive,
                    isUpdating: info.isUpdating
                )
            )

        case .none:
            nil
        }
    }

    var contentState: TangemTokenRowViewData.ContentState {
        if hasError {
            return .error(message: errorMessage ?? "")
        }

        if isBalanceLoading {
            return .loading(cached: cachedContent)
        }

        return .loaded(loadedContent)
    }

    var isBalanceLoading: Bool {
        if case .loading = balanceFiat { return true }
        if case .loading = balanceCrypto { return true }
        return false
    }

    var cachedContent: TangemTokenRowViewData.CachedContent? {
        let fiat = cachedString(from: balanceFiat)
        let crypto = cachedString(from: balanceCrypto)
        let price = cachedPrice(from: tokenPrice)

        if fiat == nil, crypto == nil, price == nil {
            return nil
        }

        return TangemTokenRowViewData.CachedContent(
            fiatBalance: fiat,
            cryptoBalance: crypto,
            price: price
        )
    }

    var loadedContent: TangemTokenRowViewData.LoadedContent {
        TangemTokenRowViewData.LoadedContent(
            balances: TangemTokenRowViewData.Balances(
                fiat: makeBalanceValue(from: balanceFiat),
                crypto: makeBalanceValue(from: balanceCrypto)
            ),
            priceInfo: priceInfo
        )
    }

    func makeBalanceValue(from state: LoadableBalanceView.State) -> TangemTokenRowViewData.BalanceValue {
        switch state {
        case .loaded(let text):
            .value(text.plainString)
        case .failed(let cached, _):
            .failed(cached: cached.plainString)
        case .loading(let cached):
            .value(cached?.plainString ?? .enDashSign)
        }
    }

    func cachedString(from state: LoadableBalanceView.State) -> String? {
        switch state {
        case .loading(let cached):
            cached?.plainString
        case .loaded(let text):
            text.plainString
        case .failed(let cached, _):
            cached.plainString
        }
    }

    func cachedPrice(from state: LoadableTextView.State) -> String? {
        guard case .loaded(let text) = state else { return nil }
        return text
    }

    var priceInfo: TangemTokenRowViewData.PriceInfo? {
        guard case .loaded(let priceText) = tokenPrice else {
            return nil
        }

        var change: TangemTokenRowViewData.PriceChange?
        if case .loaded(let changeType, let text) = priceChangeState {
            change = TangemTokenRowViewData.PriceChange(type: changeType, text: text)
        }

        return TangemTokenRowViewData.PriceInfo(price: priceText, change: change)
    }
}

// MARK: - SensitiveText.TextType + PlainString

private extension SensitiveText.TextType {
    var plainString: String {
        switch self {
        case .string(let value):
            value
        case .attributed(let attributed):
            String(attributed.characters)
        case .builder(let builder, let sensitive):
            builder(sensitive)
        }
    }
}
