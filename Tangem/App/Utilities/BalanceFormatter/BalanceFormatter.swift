//
//  BalanceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormatter {
    @Injected(\.ratesProvider) var ratesProvider: RatesProvider

    func string(for value: Decimal, formattingOptions: BalanceFormattingOptions) -> String {
        let symbol = formattingOptions.currencyCode
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencySymbol = symbol
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let valueToFormat = roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(symbol)"
    }

    func convertToFiat(value: Decimal, from cryptoCurrencyCode: String, formattingOptions: BalanceFormattingOptions) async throws -> String {
        let rate = try await ratesProvider.rate(crypto: cryptoCurrencyCode, fiat: formattingOptions.currencyCode)
        let fiatValue = value * rate
        let code = formattingOptions.currencyCode
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = code
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        if code == "RUB" {
            formatter.currencySymbol = "₽"
        }

        let valueToFormat = roundDecimal(fiatValue, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(code)"
    }

    private func roundDecimal(_ value: Decimal, with roundingType: AmountRoundingType?) -> Decimal {
        if value == 0 {
            return 0
        }

        guard let roundingType = roundingType else {
            return value
        }

        switch roundingType {
        case .shortestFraction(let roundingMode):
            return SignificantFractionDigitRounder(roundingMode: roundingMode).round(value: value)
        case .default(let roundingMode, let scale):
            return max(value, Decimal(1) / pow(10, scale)).rounded(scale: scale, roundingMode: roundingMode)
        }
    }
}
