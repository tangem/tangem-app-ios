//
//  BalanceFormattingOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormattingOptions {
    let minFractionDigits: Int
    let maxFractionDigits: Int
    let currencyCode: String
    let roundingType: AmountRoundingType?

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            roundingType: nil
        )
    }

    static func makeDefaultCryptoFormattingOptions(for currencyCode: String, maxFractionDigits: Int = 8, withRounding roundingMode: NSDecimalNumber.RoundingMode = .down) -> BalanceFormattingOptions {
        BalanceFormattingOptions(
            minFractionDigits: 2,
            maxFractionDigits: maxFractionDigits,
            currencyCode: currencyCode,
            roundingType: .default(roundingMode: roundingMode, scale: maxFractionDigits)
        )
    }
}
