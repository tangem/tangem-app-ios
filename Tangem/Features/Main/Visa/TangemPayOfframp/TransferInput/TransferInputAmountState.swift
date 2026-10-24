//
//  TransferInputAmountState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum TransferInputAmountState: Equatable {
    case empty
    case valid
    case outOfRange(min: Decimal, max: Decimal)
    case notEnoughFunds

    var isValid: Bool {
        self == .valid
    }

    var errorMessage: String? {
        switch self {
        case .empty, .valid:
            nil
        case .outOfRange(let min, let max):
            Localization.tangempayWithdrawBankAmountErrorRange(
                TangemPayOfframpAmountFormatter.format(min),
                TangemPayOfframpAmountFormatter.format(max)
            )
        case .notEnoughFunds:
            Localization.tangempayWithdrawBankAmountNotEnoughFunds
        }
    }
}
