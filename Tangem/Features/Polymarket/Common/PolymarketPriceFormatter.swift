//
//  PolymarketPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PolymarketPriceFormatter {
    static func cents(_ probability: Decimal?) -> String {
        guard let probability else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return balanceFormatter.formatDecimal(
            probability * Constants.centsPerUnit,
            formattingOptions: .predictionCents
        )
    }

    static func centsText(_ probability: Decimal?) -> String {
        guard probability != nil else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return "\(cents(probability))\(Constants.centsSuffix)"
    }

    static func percentText(_ probability: Decimal?) -> String {
        guard let probability else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return percentFormatter.format(probability, option: .predictionProbability)
    }

    private static let percentFormatter = PercentFormatter()
    private static let balanceFormatter = BalanceFormatter()
}

// MARK: - Constants

private extension PolymarketPriceFormatter {
    enum Constants {
        static let centsPerUnit: Decimal = 100
        static let centsSuffix = "¢"
    }
}

// MARK: - Formatting options

private extension BalanceFormattingOptions {
    static let predictionCents = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 1,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .default(roundingMode: .plain, scale: 1)
    )
}
