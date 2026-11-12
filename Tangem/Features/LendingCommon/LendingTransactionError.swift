//
//  LendingTransactionError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
enum LendingTransactionError: LocalizedError {
    case previousTransactionPending
    case customNonce
    case gasLimitTooLow(required: Int)

    var errorDescription: String? {
        switch self {
        case .previousTransactionPending:
            "Your previous Aave transaction is still processing. Try again once it is confirmed."
        case .customNonce:
            "A custom nonce can't be used for this deposit. Remove it in the custom fee or choose another fee speed."
        case .gasLimitTooLow(let required):
            "The gas limit is too low for this deposit. Set it to at least \(required) in the custom fee or choose another fee speed."
        }
    }
}
