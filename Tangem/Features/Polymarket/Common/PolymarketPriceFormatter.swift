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
    static func centsText(_ probability: Decimal?) -> String {
        guard let probability else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        let cents = (probability * Constants.centsPerUnit).intValue(roundingMode: .plain)

        return "\(cents)\(Constants.centsSuffix)"
    }

    static func percentText(_ probability: Decimal?) -> String {
        guard let probability else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return percentFormatter.format(probability, option: .predictionProbability)
    }

    private static let percentFormatter = PercentFormatter()
}

// MARK: - Constants

private extension PolymarketPriceFormatter {
    enum Constants {
        static let centsPerUnit: Decimal = 100
        static let centsSuffix = "¢"
    }
}
