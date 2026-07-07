//
//  StakingTransactionValidationError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Error thrown when a transaction fails local staking validation.
public enum StakingTransactionValidationError: Error, Equatable {
    /// The unsigned data is empty or cannot be parsed.
    case emptyOrMalformedData

    /// The transaction is not a staking operation for the specified network.
    case notAStakingTransaction(network: String, details: String)
}
