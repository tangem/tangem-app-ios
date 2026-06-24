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

    private static var cachedNumberFormatters: [CurrencyCode: NumberFormatter] = [:]

    private let balanceFormatter = BalanceFormatter()

    func formatValue(_ value: Decimal) -> Result {
        let numberFormatter = numberFormatter(currencyCode: AppSettings.shared.selectedCurrencyCode)
        let formattedText = prefix(value) + balanceFormatter.formatFiatBalance(value, formatter: numberFormatter)
        return Result(formattedText: formattedText)
    }
}

// MARK: - Helpers

private extension PriceValueFormatter {
    func numberFormatter(currencyCode: CurrencyCode) -> NumberFormatter {
        if let cached = Self.cachedNumberFormatters[currencyCode] {
            return cached
        } else {
            let formatter = balanceFormatter.makeDefaultFiatFormatter(
                forCurrencyCode: currencyCode,
                formattingOptions: .defaultFiatFormattingOptions
            )
            Self.cachedNumberFormatters[currencyCode] = formatter
            return formatter
        }
    }

    func prefix(_ value: Decimal) -> String {
        switch ChangeSignType(from: value) {
        case .positive: .plusSign
        case .negative, .neutral: .empty
        }
    }
}

// MARK: - Types

extension PriceValueFormatter {
    struct Result {
        let formattedText: String
    }
}
