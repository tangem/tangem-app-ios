//
//  CommonTokenPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonTokenPriceFormatter {
    private let balanceFormatter: BalanceFormatter

    init(balanceFormatter: BalanceFormatter) {
        self.balanceFormatter = balanceFormatter
    }
}

// MARK: - FeeFormatter

extension CommonTokenPriceFormatter: TokenPriceFormatter {
    func formatFiatBalance(_ value: Decimal?) -> String {
        guard let value else {
            return balanceFormatter.formatFiatBalance(value)
        }

        let fiatFormattingOptions: BalanceFormattingOptions = value > Constants.boundaryLowDigitOptions ? .defaultFiatFormattingOptions : .lowPriceFiatFormattingOptions
        return balanceFormatter.formatDecimal(value, formattingOptions: fiatFormattingOptions)
    }
}

extension CommonTokenPriceFormatter {
    enum Constants {
        // Need use for token with low very price, when display 2-6 digits with scale 6
        static let boundaryLowDigitOptions: Decimal = 0.01
    }
}
