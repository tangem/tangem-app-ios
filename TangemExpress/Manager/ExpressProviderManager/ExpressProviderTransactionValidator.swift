//
//  ExpressProviderTransactionValidator.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressProviderTransactionValidator {
    /// Checks whether the given transaction size is acceptable for processing.
    /// This validation is specific to the Li.Fi provider and applies only to the Solana blockchain. (Now)
    ///
    /// - Returns: `true` if the transaction size is supported, otherwise `false`.
    func validateTransactionSize(data: String) -> Bool
}
