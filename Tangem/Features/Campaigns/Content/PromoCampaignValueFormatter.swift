//
//  PromoCampaignValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PromoCampaignValueFormatter {
    private let locale: Locale
    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter: PercentFormatter

    init(locale: Locale = .current) {
        self.locale = locale
        percentFormatter = PercentFormatter(locale: locale)
    }

    func format(_ value: Decimal, type: PromoCampaignsDTO.ValueType?, currency: String?, tokenSymbols: Set<String>) -> String {
        switch type {
        case .percent:
            return formatPercent(value)
        case .number, .text:
            return formatNumber(value)
        case .money, .none:
            return currency.map { formatMoney(value, currency: $0, tokenSymbols: tokenSymbols) } ?? formatNumber(value)
        }
    }
}

// MARK: - Private

private extension PromoCampaignValueFormatter {
    func formatPercent(_ value: Decimal) -> String {
        percentFormatter.format(value / 100, option: .promoCampaign)
    }

    func formatMoney(_ value: Decimal, currency: String, tokenSymbols: Set<String>) -> String {
        let currencyCode = currency.uppercased()

        guard
            !tokenSymbols.contains(where: { $0.uppercased() == currencyCode }),
            Locale.commonISOCurrencyCodes.contains(currencyCode)
        else {
            let options = Constants.cryptoFormattingOptions
            let formatter = BalanceNumberFormatterCache.cryptoFormatter(forCurrencyCode: currency, locale: locale, formattingOptions: options)
            return balanceFormatter.formatCryptoBalance(value, currencyCode: currency, formattingOptions: options, formatter: formatter)
        }

        var options = BalanceFormattingOptions.defaultFiatFormattingOptions

        if value == value.rounded() {
            options.minFractionDigits = 0
        }

        let formatter = BalanceNumberFormatterCache.fiatFormatter(forCurrencyCode: currencyCode, locale: locale, formattingOptions: options)
        return balanceFormatter.formatFiatBalance(value, currencyCode: currencyCode, formattingOptions: options, formatter: formatter)
    }

    func formatNumber(_ value: Decimal) -> String {
        let options = Constants.cryptoFormattingOptions
        let formatter = BalanceNumberFormatterCache.decimalFormatter(locale: locale, formattingOptions: options)
        return balanceFormatter.formatDecimal(value, formattingOptions: options, formatter: formatter)
    }
}

// MARK: - Constants

private extension PromoCampaignValueFormatter {
    enum Constants {
        static let cryptoFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 8,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }
}
