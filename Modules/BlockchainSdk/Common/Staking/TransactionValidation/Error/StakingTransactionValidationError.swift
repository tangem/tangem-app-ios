//
//  StakingTransactionValidationError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Error thrown when a transaction fails staking validation.
public enum StakingTransactionValidationError: Error, Equatable {
    /// The unsigned data is empty or cannot be parsed.
    case emptyOrMalformedData

    /// The transaction is not a staking operation for the specified network.
    case notAStakingTransaction(network: String, details: String)

    // MARK: - BlockAid Validation Errors

    /// BlockAid flagged the transaction as potentially dangerous (warning level).
    case blockaidWarning(description: String)

    /// BlockAid flagged the transaction as malicious.
    case blockaidMalicious(description: String)

    /// BlockAid validation failed (network error, API error, etc.).
    case blockaidValidationFailed(description: String)

    /// The blockchain is not supported by BlockAid API.
    case blockaidUnsupportedBlockchain(name: String)
}
