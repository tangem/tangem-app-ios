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
            .updating(balanceValue(text))
        case .loaded(let text):
            .loaded(balanceValue(text))
        case .failed(let text, let icon):
            .loaded(balanceValue(text), isStale: icon != nil)
        }
    }

    private var cryptoBalance: TokenRowValue {
        switch cryptoBalanceState {
        case .loading:
            .loading
        case .loadingCached(let text):
            .updating(balanceValue(text))
        case .loaded(let text), .failed(let text, _):
            .loaded(balanceValue(text))
        }
    }

    private func balanceValue(_ text: SensitiveText.TextType) -> UtilBalance.Value {
        switch text {
        case .string(let value):
            .string(value)
        case .attributed(let value):
            .attributed(value)
        case .builder(let builder, let sensitive):
            .string(builder(sensitive))
        }
    }
}
