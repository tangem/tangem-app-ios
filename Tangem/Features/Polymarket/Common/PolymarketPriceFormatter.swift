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
    static func cents(_ probability: Decimal?, isResolved: Bool = false) -> String {
        guard let probability else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return balanceFormatter.formatDecimal(
            displayed(probability * Constants.centsPerUnit, isResolved: isResolved),
            formattingOptions: .predictionCents
        )
    }

    static func centsText(_ probability: Decimal?, isResolved: Bool = false) -> String {
        guard probability != nil else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return "\(cents(probability, isResolved: isResolved))\(Constants.centsSuffix)"
    }

    private static func displayed(_ cents: Decimal, isResolved: Bool) -> Decimal {
        guard !isResolved else { return cents }

        return min(max(cents, Constants.minUnresolvedCents), Constants.maxUnresolvedCents)
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
        static let minUnresolvedCents: Decimal = 0.1
        static let maxUnresolvedCents: Decimal = 99.9
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
