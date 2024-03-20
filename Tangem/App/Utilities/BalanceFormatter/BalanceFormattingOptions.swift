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
    let roundingType: AmountRoundingType?

    static let defaultFiatRoundingMode: NSDecimalNumber.RoundingMode = .plain

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            roundingType: .default(roundingMode: defaultFiatRoundingMode, scale: 2)
        )
    }

    static var defaultCryptoFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }
}
