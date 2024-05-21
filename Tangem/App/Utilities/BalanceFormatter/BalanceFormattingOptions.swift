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
    let formatEpsilonAsLowestRepresentableValue: Bool
    let roundingType: AmountRoundingType?

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
    }

    static var lowPriceFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 6,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: 6)
        )
    }

    static var defaultCryptoFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }

    static var defaultCryptoFeeFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: Self.defaultCryptoFormattingOptions.minFractionDigits,
            maxFractionDigits: 6,
            formatEpsilonAsLowestRepresentableValue: Self.defaultCryptoFormattingOptions.formatEpsilonAsLowestRepresentableValue,
            roundingType: Self.defaultCryptoFormattingOptions.roundingType
        )
    }
}
