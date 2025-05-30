//
//  SendAmountFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendAmountFormatter {
    let fiatCurrencyCode: String
    let balanceFormatter: BalanceFormatter
    let cryptoValueFormatter: SendCryptoValueFormatter

    init(
        tokenItem: TokenItem,
        fiatItem: FiatItem,
        trimFractions: Bool = true,
        balanceFormatter: BalanceFormatter = .init()
    ) {
        fiatCurrencyCode = fiatItem.currencyCode
        self.balanceFormatter = balanceFormatter

        cryptoValueFormatter = .init(
            decimals: tokenItem.decimalCount,
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: trimFractions
        )
    }

    /// 0,00 is value is nil
    func formattedAlternative(sendAmount: SendAmount?, type: SendAmountCalculationType) -> String {
        switch (sendAmount?.type, type) {
        // Zero fiat formatted
        case (.none, .crypto), (.typical(_, .none), _):
            return balanceFormatter.formatFiatBalance(0, currencyCode: fiatCurrencyCode)

        case (.typical(_, .some(let fiat)), _):
            return balanceFormatter.formatFiatBalance(fiat, currencyCode: fiatCurrencyCode)

        case (.alternative(_, .some(let crypto)), _):
            if let string = cryptoValueFormatter.string(from: crypto) {
                return string
            }

            fallthrough

        // Zero crypto formatted
        case (.none, .fiat), (.alternative(_, .none), _):
            return cryptoValueFormatter.string(from: 0) ?? "0"
        }
    }
}
