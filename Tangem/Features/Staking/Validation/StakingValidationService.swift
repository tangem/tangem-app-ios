//
//  StakingValidationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk
import TangemFoundation

protocol StakingValidationProvider {
    func validate(_ transaction: StakingTransactionAction) async -> StakingValidationResult
}

// MARK: - Result

struct StakingValidationResult {
    let state: StakingValidationState
    let transaction: StakingTransactionAction?
}

// MARK: - Service

/// High-level service for validating staking transactions.
/// Extracts raw transaction data, runs validation, logs analytics, and returns result.
struct StakingValidationService: StakingValidationProvider {
    private let validator: StakingTransactionValidator
    private let analyticsLogger: StakingValidationAnalyticsLogger

    init(validator: StakingTransactionValidator, analyticsLogger: StakingValidationAnalyticsLogger) {
        self.validator = validator
        self.analyticsLogger = analyticsLogger
    }

    func validate(_ transaction: StakingTransactionAction) async -> StakingValidationResult {
        let rawTransactions = transaction.transactions.compactMap { tx -> String? in
            guard case .raw(let data) = tx.unsignedTransactionData else { return nil }
            return data
        }

        guard !rawTransactions.isEmpty else {
            return handleMissingRawTransactions()
        }

        do {
            try await validator.validate(rawTransactions)
            return handleSuccess(transaction: transaction)
        } catch is CancellationError {
            return handleCancellation()
        } catch let error as StakingTransactionValidationError {
            return handleLocalError(error)
        } catch let error as RemoteStakingValidationError {
            return handleRemoteError(error, transaction: transaction)
        } catch {
            return handleUnexpectedError(error, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingValidationService {
    /// No raw payload to inspect — treat as a blind-signing attempt and block.
    func handleMissingRawTransactions() -> StakingValidationResult {
        analyticsLogger.logNoRawTransactions()
        return StakingValidationResult(state: .blocked, transaction: nil)
    }

    /// Both local and remote layers passed — allow the transaction.
    func handleSuccess(transaction: StakingTransactionAction) -> StakingValidationResult {
        analyticsLogger.logSuccess()
        return StakingValidationResult(state: .validated, transaction: transaction)
    }

    /// Validation was superseded or cancelled — reset to idle without a verdict.
    func handleCancellation() -> StakingValidationResult {
        StakingValidationResult(state: .idle, transaction: nil)
    }

    /// Local validator rejected the payload (not a staking tx / malformed) — block.
    func handleLocalError(_ error: StakingTransactionValidationError) -> StakingValidationResult {
        analyticsLogger.logLocalError(error)
        return StakingValidationResult(state: .blocked, transaction: nil)
    }

    /// Remote (BlockAid) verdict — map warning/malicious/failed to the matching state.
    func handleRemoteError(_ error: RemoteStakingValidationError, transaction: StakingTransactionAction) -> StakingValidationResult {
        analyticsLogger.logRemoteError(error)
        return StakingValidationResult(state: mapToValidationState(remoteError: error), transaction: transaction)
    }

    /// Backstop for unexpected errors — log, then fail open (the local layer already vetted the tx).
    func handleUnexpectedError(_ error: Error, transaction: StakingTransactionAction) -> StakingValidationResult {
        AppLogger.error("Unexpected staking validation error", error: error)
        let remoteError = RemoteStakingValidationError.unknown(description: "\(error)")
        analyticsLogger.logRemoteError(remoteError)
        return StakingValidationResult(state: mapToValidationState(remoteError: remoteError), transaction: transaction)
    }

    func mapToValidationState(remoteError: RemoteStakingValidationError) -> StakingValidationState {
        switch remoteError {
        case .warning:
            .warning
        case .malicious:
            .blocked
        case .validationFailed:
            .validated
        case .unknown:
            .validated
        }
    }
}
