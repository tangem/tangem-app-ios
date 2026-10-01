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

    /// Reward amounts arrive in base units and can be dust, so the token's own precision is kept instead of
    /// the default eight digits.
    func format(baseUnits: BigUInt, decimals: Int, symbol: String) -> String? {
        guard let baseUnitsValue = Decimal(string: String(baseUnits)) else {
            return nil
        }

        let value = baseUnitsValue / pow(10, decimals)
        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: min(2, decimals),
            maxFractionDigits: decimals,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .down, scale: decimals)
        )

        return balanceFormatter.formatCryptoBalance(value, currencyCode: symbol, formattingOptions: formattingOptions)
    }
}
