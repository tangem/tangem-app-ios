//
//  ValidationErrorContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Carries additional information for a failed validation of the transaction.
struct ValidationErrorContext: Hashable {
    /// `true` when the transaction is denominated in the same currency as the fee currency for the blockchain, `false` otherwise.
    let isFeeCurrency: Bool
    let feeAmount: Decimal
}
