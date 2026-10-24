//
//  TangemPayOfframpAmountFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

enum TangemPayOfframpAmountFormatter {
    static func format(_ amount: Decimal, currencyCode: String = TangemPayUtilities.fiatItem.currencyCode) -> String {
        TangemPayFiatAmountFormatter().format(amount, currencyCode: currencyCode, hidesFractionForWholeAmounts: true)
    }

    static func formatBalance(_ balance: Decimal) -> String {
        TangemPayFiatAmountFormatter().format(
            balance.rounded(scale: Constants.fractionDigits, roundingMode: .down),
            currencyCode: TangemPayUtilities.fiatItem.currencyCode
        )
    }
}

// MARK: - Constants

private extension TangemPayOfframpAmountFormatter {
    enum Constants {
        static let fractionDigits = 2
    }
}
