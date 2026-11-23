//
//  LendingDepositProjection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct LendingDepositProjection {
    let currentApy: String
    let performanceFee: String

    private let netApy: Decimal
    private let currencyCode: String
    private let locale: Locale

    init(
        currentApy: Decimal,
        performanceFee: Decimal,
        currencyCode: String = AppSettings.shared.selectedCurrencyCode,
        locale: Locale = .current
    ) {
        let percentFormatter = PercentFormatter(locale: locale)
        self.currentApy = percentFormatter.format(currentApy, option: .yieldPickerRate)
        self.performanceFee = percentFormatter.format(performanceFee, option: .performanceFee)
        netApy = currentApy * (1 - performanceFee)
        self.currencyCode = currencyCode
        self.locale = locale
    }

    func yearlyEarnings(fiatAmount: Decimal) -> String {
        let earnings = fiatAmount * netApy
        let isUnderOneUnit = earnings.rounded(scale: 2, roundingMode: .plain) < 1
        let options: BalanceFormattingOptions = isUnderOneUnit ? .defaultFiatFormattingOptions : .wholeFiatFormattingOptions
        let formatter = BalanceNumberFormatterCache.fiatFormatter(forCurrencyCode: currencyCode, locale: locale, formattingOptions: options)
        let formatted = BalanceFormatter().formatFiatBalance(earnings, currencyCode: currencyCode, formattingOptions: options, formatter: formatter)

        return AppConstants.tildeSign + Localization.forYouEarnPerYear(formatted)
    }
}
