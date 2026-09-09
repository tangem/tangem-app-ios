//
//  TransferInputAmountState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

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
            // [REDACTED_TODO_COMMENT]
            "Please set amount from \(Self.format(min)) to \(Self.format(max))"
        case .notEnoughFunds:
            // [REDACTED_TODO_COMMENT]
            "Not enough funds"
        }
    }
}

// MARK: - Bounds formatting

private extension TransferInputAmountState {
    static func format(_ value: Decimal) -> String {
        BalanceFormatter().formatFiatBalance(
            value,
            currencyCode: TangemPayUtilities.fiatItem.currencyCode,
            formattingOptions: .init(
                minFractionDigits: 0,
                maxFractionDigits: 0,
                formatEpsilonAsLowestRepresentableValue: false,
                roundingType: .default(roundingMode: .plain, scale: 0)
            )
        )
    }
}
