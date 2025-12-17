//
//  YieldModuleDustFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModuleDustFilter {
    let feeConverter: YieldModuleFeeFormatter

    /// Filters the undeposited amount based on fiat value.
    /// - For major currencies (USD/EUR/etc.), ignores amounts below or equal to 0.1.
    /// - For other currencies, compares against a configurable minimum top-up threshold.
    /// Returns nil when the amount is too small to be processed.
    func filterUndepositedAmount(
        _ undepositedAmount: Decimal?,
        minimalTopupAmountInFiat: @autoclosure () async -> Decimal?
    ) async -> Decimal? {
        guard let undepositedAmount,
              let undepositedInFiat = try? await feeConverter.convertToFiat(undepositedAmount, currency: .token)
        else {
            return nil
        }

        let selectedCurrency = await AppSettings.shared.selectedCurrencyCode
        let majorCurrencies = [
            AppConstants.usdCurrencyCode,
            AppConstants.eurCurrencyCode,
            AppConstants.cadCurrencyCode,
            AppConstants.gbpCurrencyCode,
            AppConstants.audCurrencyCode,
        ]

        if majorCurrencies.contains(selectedCurrency) {
            return undepositedInFiat >= Constants.majorCurrenciesMinUndepositedAmount ? undepositedAmount : nil
        }

        if let minimalTopupAmountInFiat = await minimalTopupAmountInFiat(),
           undepositedInFiat >= minimalTopupAmountInFiat {
            return undepositedAmount
        }

        return nil
    }
}

private extension YieldModuleDustFilter {
    enum Constants {
        static let majorCurrenciesMinUndepositedAmount: Decimal = 0.1
    }
}
