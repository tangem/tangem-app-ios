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

// MARK: - Protocol

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
            analyticsLogger.logNoRawTransactions()
            return StakingValidationResult(state: .blocked, transaction: nil)
        }

        do {
            try await validator.validate(rawTransactions)
            analyticsLogger.logSuccess()
            return StakingValidationResult(state: .validated, transaction: transaction)
        } catch is CancellationError {
            return StakingValidationResult(state: .idle, transaction: nil)
        } catch let error as StakingTransactionValidationError {
            analyticsLogger.logLocalError(error)
            return StakingValidationResult(state: .blocked, transaction: nil)
        } catch let error as RemoteStakingValidationError {
            analyticsLogger.logRemoteError(error)
            let state = mapToValidationState(remoteError: error)
            return StakingValidationResult(state: state, transaction: transaction)
        } catch {
            return StakingValidationResult(state: .validated, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingValidationService {
    func mapToValidationState(remoteError: RemoteStakingValidationError) -> StakingValidationState {
        switch remoteError {
        case .warning:
            .warning
        case .malicious:
            .blocked
        case .validationFailed:
            .validated
        }
    }
}
