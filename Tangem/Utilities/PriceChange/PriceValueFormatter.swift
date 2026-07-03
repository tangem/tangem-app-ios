//
//  PriceValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PriceValueFormatter {
    fileprivate typealias CurrencyCode = String

    private static let cachedNumberFormatters = NSCacheWrapper<CacheKey, NumberFormatter>()

    private let balanceFormatter = BalanceFormatter()

    func formatValue(_ value: Decimal) -> Result {
        let currencyCode = AppSettings.shared.selectedCurrencyCode
        let formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions

        let numberFormatter = numberFormatter(
            locale: .current,
            currencyCode: currencyCode,
            formattingOptions: formattingOptions
        )

        let formattedFiatBalance = balanceFormatter.formatFiatBalance(
            value,
            formattingOptions: formattingOptions,
            formatter: numberFormatter
        )

        let formattedPrice = priceSign(value) + formattedFiatBalance
        return Result(formattedText: formattedPrice)
    }
}

// MARK: - Helpers

private extension PriceValueFormatter {
    func numberFormatter(
        locale: Locale,
        currencyCode: CurrencyCode,
        formattingOptions: BalanceFormattingOptions
    ) -> NumberFormatter {
        let cacheKey = CacheKey(
            localeIdentifier: locale.identifier,
            currencyCode: currencyCode,
            formattingOptions: formattingOptions
        )

        if let cached = Self.cachedNumberFormatters.value(forKey: cacheKey) {
            return cached
        } else {
            let formatter = balanceFormatter.makeDefaultFiatFormatter(
                forCurrencyCode: currencyCode,
                formattingOptions: formattingOptions
            )
            Self.cachedNumberFormatters.setValue(formatter, forKey: cacheKey)
            return formatter
        }
    }

    func priceSign(_ value: Decimal) -> String {
        switch ChangeSignType(from: value) {
        case .positive: .plusSign
        case .negative, .neutral: .empty
        }
    }
}

// MARK: - Private types

private extension PriceValueFormatter {
    struct CacheKey: Hashable {
        let localeIdentifier: String
        let currencyCode: String
        let formattingOptions: BalanceFormattingOptions
    }
}

// MARK: - Types

extension PriceValueFormatter {
    struct Result {
        let formattedText: String
    }
}
