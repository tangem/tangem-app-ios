//
//  YieldIncentiveAmountFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldIncentiveAmountFormatter {
    private let balanceFormatter = BalanceFormatter()

    func format(baseUnits: BigUInt, decimals: Int, symbol: String) -> String? {
        guard let baseUnitsValue = Decimal(string: String(baseUnits)) else {
            return nil
        }

        let value = baseUnitsValue / pow(10, decimals)
        let fractionDigits = min(decimals, Constants.maxFractionDigits)
        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: min(2, fractionDigits),
            maxFractionDigits: fractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .down, scale: fractionDigits)
        )

        return balanceFormatter.formatCryptoBalance(value, currencyCode: symbol, formattingOptions: formattingOptions)
    }
}

private extension YieldIncentiveAmountFormatter {
    enum Constants {
        static let maxFractionDigits = 8
    }
}
