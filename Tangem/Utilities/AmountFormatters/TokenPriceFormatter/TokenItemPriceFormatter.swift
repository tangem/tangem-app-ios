//
//  CommonTokenPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS, deprecated: 100000.0, message: "Temporary solution for token list on the main screen only, do not use ([REDACTED_INFO])")
struct TokenItemPriceFormatter {
    private let balanceFormatter = BalanceFormatter()

    private var lowPriceFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 6,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: 6)
        )
    }

    func formatPrice(_ value: Decimal?) -> String {
        guard let value else {
            return balanceFormatter.formatFiatBalance(value)
        }

        let fiatFormattingOptions: BalanceFormattingOptions = value >= Constants.boundaryLowDigitOptions
            ? .defaultFiatFormattingOptions
            : lowPriceFiatFormattingOptions

        return balanceFormatter.formatFiatBalance(value, formattingOptions: fiatFormattingOptions)
    }
}

// MARK: - Constants

private extension TokenItemPriceFormatter {
    enum Constants {
        /// Need use for token with low very price, when display 2-6 digits with scale 6
        static let boundaryLowDigitOptions: Decimal = 0.01
    }
}
