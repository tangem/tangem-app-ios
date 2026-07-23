//
//  SendAmountFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendAmountFormatter {
    private let fiatCurrencyCode: String
    private let balanceFormatter: BalanceFormatter
    private let decimalNumberFormatter: DecimalNumberFormatter
    private let cryptoValueFormatter: SendCryptoValueFormatter
    private let fiatPrefixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions

    init(
        tokenItem: TokenItem,
        fiatItem: FiatItem,
        balanceFormatter: BalanceFormatter = .init()
    ) {
        fiatCurrencyCode = fiatItem.currencyCode
        self.balanceFormatter = balanceFormatter

        decimalNumberFormatter = .init(maximumFractionDigits: tokenItem.decimalCount)
        cryptoValueFormatter = .init(
            decimals: tokenItem.decimalCount,
            currencySymbol: tokenItem.currencySymbol,
            trimFractions: false
        )
        fiatPrefixSuffixOptions = SendDecimalNumberTextField.PrefixSuffixOptionsFactory()
            .makeFiatOptions(fiatCurrencyCode: fiatItem.currencyCode)
    }

    /// Crypto values come without a `currencySymbol` (the token symbol is shown separately),
    /// fiat values carry the localized currency symbol
    func formatMain(amount: SendAmount?) -> String {
        switch amount?.type {
        case .typical(.some(let crypto), _):
            return cryptoValueFormatter.string(from: crypto, prefixSuffixOptions: .none)
        case .alternative(.some(let fiat), _):
            return cryptoValueFormatter.string(from: fiat, prefixSuffixOptions: fiatPrefixSuffixOptions)
        default:
            return decimalNumberFormatter.mapToString(decimal: .zero)
        }
    }

    /// 0,00 is value is nil
    func formattedAlternative(sendAmount: SendAmount?, type: SendAmountCalculationType) -> String {
        switch (sendAmount?.type, type) {
        // Zero fiat formatted
        case (.none, .crypto):
            return balanceFormatter.formatFiatBalance(0, currencyCode: fiatCurrencyCode)

        // Custom tokens - we have only crypto value
        case (.typical(.some, .none), _):
            return BalanceFormatter.defaultEmptyBalanceString

        case (.typical(_, .some(let fiat)), _):
            return balanceFormatter.formatFiatBalance(fiat, currencyCode: fiatCurrencyCode)

        case (.alternative(_, .some(let crypto)), _):
            return cryptoValueFormatter.string(from: crypto)

        // Zero crypto formatted
        case (.typical(.none, .none), _), (.none, .fiat), (.alternative(_, .none), _):
            return cryptoValueFormatter.string(from: 0)
        }
    }
}
