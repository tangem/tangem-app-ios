//
//  RemoteStakingValidationError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Error thrown when a staking transaction fails remote validation (BlockAid).
enum RemoteStakingValidationError: Error, Equatable {
    /// Transaction flagged as potentially dangerous (warning level).
    case warning(description: String)

    /// Transaction flagged as malicious.
    case malicious(description: String)

    /// Remote validation failed (network error, API error, etc.).
    case validationFailed(description: String)

    /// Unexpected/unclassified error surfaced during remote validation.
    case unknown(description: String)
}
