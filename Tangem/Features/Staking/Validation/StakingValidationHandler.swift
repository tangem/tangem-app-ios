//
//  StakingValidationHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import BlockchainSdk

/// Handles validation lifecycle for staking models.
/// Triggers validation, cancellation, and publishes state.
final class StakingValidationHandler: StakingValidationStateProvider {
    // MARK: - Properties

    private let stakingManager: StakingManager
    private let validationProvider: StakingValidationProvider
    private let stateSubject = CurrentValueSubject<StakingValidationState, Never>(.idle)

    private var validationTask: Task<Void, Never>?
    private var validatedTransaction: ValidatedTransaction?

    var validationState: AnyPublisher<StakingValidationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Init

    init(
        stakingManager: StakingManager,
        validationProvider: StakingValidationProvider
    ) {
        self.stakingManager = stakingManager
        self.validationProvider = validationProvider
    }

    deinit {
        validationTask?.cancel()
    }

    // MARK: - Public methods

    func validate(action: StakingAction) {
        invalidate()
        stateSubject.send(.validating)
        validationTask = makeValidationTask(action: action)
    }

    func reset() {
        invalidate()
        validationTask = nil
        stateSubject.send(.idle)
    }

    /// Returns validated transaction if still valid, or `nil` if expired/missing.
    func validatedTransaction(for blockchain: Blockchain) -> StakingTransactionAction? {
        guard let validatedTransaction, !validatedTransaction.isExpired(for: blockchain) else {
            return nil
        }
        return validatedTransaction.transaction
    }

    /// Rebuilds and revalidates transaction. Use when cache is expired.
    func revalidate(action: StakingAction) async -> StakingTransactionAction? {
        guard let transaction = await buildTransaction(action: action) else {
            return nil
        }

        let result = await validationProvider.validate(transaction)
        await handleValidationResult(result)

        guard result.state.allowsSending else {
            return nil
        }

        return transaction
    }
}

private extension StakingValidationHandler {
    // MARK: - Private logic

    func invalidate() {
        validationTask?.cancel()
        validatedTransaction = nil
    }

    func makeValidationTask(action: StakingAction) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }

            guard let transaction = await buildTransaction(action: action) else {
                return
            }

            let result = await validationProvider.validate(transaction)
            await handleValidationResult(result)
        }
    }

    func buildTransaction(action: StakingAction) async -> StakingTransactionAction? {
        do {
            return try await stakingManager.transaction(action: action)
        } catch is CancellationError {
            return nil
        } catch {
            // Network/StakeKit error during build — allow to proceed without validation (fail-open)
            await handleBuildError()
            return nil
        }
    }

    @MainActor
    func handleBuildError() {
        guard !Task.isCancelled else { return }

        stateSubject.send(.validated)
        validationTask = nil
    }

    @MainActor
    func handleValidationResult(_ result: StakingValidationResult) {
        guard !Task.isCancelled else { return }

        if let transaction = result.transaction {
            validatedTransaction = ValidatedTransaction(transaction: transaction, validatedAt: Date())
        }
        stateSubject.send(result.state)
        validationTask = nil
    }
}

// MARK: - ValidatedTransaction

private extension StakingValidationHandler {
    struct ValidatedTransaction {
        let transaction: StakingTransactionAction
        let validatedAt: Date

        func isExpired(for blockchain: Blockchain) -> Bool {
            guard let timeout = blockchain.stakingCacheTimeout else { return false }
            return Date().timeIntervalSince(validatedAt) >= timeout
        }
    }
}

// MARK: - Blockchain + Staking Cache

private extension Blockchain {
    /// Solana blockhash expires in ~60-90 sec, we use 50 sec safety margin.
    var stakingCacheTimeout: TimeInterval? {
        switch self {
        case .solana: return 50
        default: return nil
        }
    }
}
