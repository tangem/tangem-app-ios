//
//  CollectiblesFormatting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension BalanceFormattingOptions {
    static let collectiblesDollars = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: true,
        roundingType: .default(roundingMode: .plain, scale: 2)
    )
}

extension PercentFormatter.Option {
    static let collectibles = PercentFormatter.Option(fractionDigits: .init(min: 0, max: 0), prefix: .empty, suffix: .yield)
}

enum CollectiblesPriceFormatter {
    private static let balanceFormatter = BalanceFormatter()
    private static let locale = Locale(identifier: "en_US")

    static func formatAmount(
        _ value: Decimal,
        ticker: String,
        formattingOptions: BalanceFormattingOptions = .collectiblesDollars
    ) -> String {
        let formatter = balanceFormatter.makeDecimalFormatter(formattingOptions: formattingOptions)
        formatter.locale = locale
        let amount = balanceFormatter.formatDecimal(value, formattingOptions: formattingOptions, formatter: formatter)

        return "\(amount) \(ticker)"
    }

    static func format(
        _ value: Decimal,
        currencyCode: String = AppConstants.usdCurrencyCode,
        formattingOptions: BalanceFormattingOptions = .collectiblesDollars
    ) -> String {
        balanceFormatter.formatFiatBalance(
            value,
            currencyCode: currencyCode,
            formattingOptions: formattingOptions,
            formatter: BalanceNumberFormatterCache.fiatFormatter(
                forCurrencyCode: currencyCode,
                locale: locale,
                formattingOptions: formattingOptions
            )
        )
    }

    static func formatWithCents(_ value: Decimal) -> String {
        format(value, formattingOptions: .defaultFiatFormattingOptions)
    }
}
