//
//  TangemPayOfframpAmountFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

enum TangemPayOfframpAmountFormatter {
    static func format(_ amount: Decimal) -> String {
        BalanceFormatter().formatFiatBalance(
            amount,
            currencyCode: TangemPayUtilities.fiatItem.currencyCode,
            formattingOptions: Constants.formattingOptions
        )
    }
}

// MARK: - Constants

private extension TangemPayOfframpAmountFormatter {
    enum Constants {
        static let fractionDigits = 2

        static let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: fractionDigits,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: fractionDigits)
        )
    }
}
