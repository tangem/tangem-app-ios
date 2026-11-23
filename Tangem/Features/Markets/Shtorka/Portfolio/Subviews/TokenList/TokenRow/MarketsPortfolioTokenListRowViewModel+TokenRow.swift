//
//  MarketsPortfolioTokenListRowViewModel+TokenRow.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension MarketsPortfolioTokenListRowViewModel {
    /// `nil` for a crypto balance warning: `TokenRow` has no accessory for it yet, so such a row keeps the legacy layout.
    func tokenRowContent(onTap: @escaping () -> Void) -> TokenRow.Content? {
        if isNoAddress {
            return .note(
                icon: tokenIconInfo,
                title: tokenName,
                quote: networkName,
                priceChange: nil,
                text: noAddressText,
                onTap: onTap
            )
        }

        if case .failed(_, .some) = cryptoBalanceState {
            return nil
        }

        return .balance(
            icon: .init(tokenIconInfo),
            title: tokenName,
            titleAccessory: nil,
            quote: networkName,
            priceChange: nil,
            balance: .init(fiat: fiatBalance, crypto: cryptoBalance),
            indicator: nil,
            bubble: nil,
            onTap: onTap
        )
    }

    private var fiatBalance: TokenRow.Balance.Fiat {
        switch fiatBalanceState {
        case .loading:
            .loading
        case .loadingCached(let text):
            .updating(UtilBalance.Value(text))
        case .loaded(let text):
            .loaded(UtilBalance.Value(text))
        case .failed(let text, let icon):
            .loaded(UtilBalance.Value(text), isStale: icon != nil)
        }
    }

    private var cryptoBalance: TokenRowValue {
        switch cryptoBalanceState {
        case .loading:
            .loading
        case .loadingCached(let text):
            .updating(UtilBalance.Value(text))
        case .loaded(let text), .failed(let text, _):
            .loaded(UtilBalance.Value(text))
        }
    }
}
