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
    private var cachedTransaction: ValidatedTransaction?

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
        guard let cachedTransaction, !cachedTransaction.isExpired(for: blockchain) else {
            return nil
        }
        return cachedTransaction.transaction
    }

    /// Rebuilds and revalidates transaction. Use when cache is expired.
    /// Returns `.validated` if transaction is safe, `.blocked` if malicious, or `nil` if build failed (fail-open).
    func revalidate(action: StakingAction) async -> RevalidationResult? {
        guard let transaction = await buildTransaction(action: action) else {
            return nil
        }

        let result = await validationProvider.validate(transaction)
        await handleValidationResult(result)

        guard result.state.allowsSending else {
            return .blocked
        }

        return .validated(transaction)
    }

    /// Resolves transaction from cache, revalidation, or builds new one.
    /// - Returns: Validated transaction ready to send
    /// - Throws: `StakingModelError.transactionBlocked` if validation failed
    func resolveTransaction(action: StakingAction, blockchain: Blockchain) async throws -> StakingTransactionAction {
        if let validated = validatedTransaction(for: blockchain) {
            return validated
        }

        switch await revalidate(action: action) {
        case .validated(let tx):
            return tx
        case .blocked:
            throw StakingModelError.transactionBlocked
        case .none:
            return try await stakingManager.transaction(action: action)
        }
    }
}

// MARK: - Optional + StakingValidationHandler

/// Resolves transaction with validation if handler exists, or falls back to direct `stakingManager.transaction()`.
/// This is the feature-toggle kill-switch: when `stakingTransactionValidation` is off, handler is nil.
extension Optional where Wrapped == StakingValidationHandler {
    func resolveTransaction(
        action: StakingAction,
        blockchain: Blockchain,
        stakingManager: StakingManager
    ) async throws -> StakingTransactionAction {
        guard let self else {
            return try await stakingManager.transaction(action: action)
        }
        return try await self.resolveTransaction(action: action, blockchain: blockchain)
    }
}

// MARK: - RevalidationResult

extension StakingValidationHandler {
    enum RevalidationResult {
        case validated(StakingTransactionAction)
        case blocked
    }
}

private extension StakingValidationHandler {
    // MARK: - Private logic

    func invalidate() {
        validationTask?.cancel()
        cachedTransaction = nil
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

        // Only cache transaction if validation allows sending (not blocked/malicious)
        if let transaction = result.transaction, result.state.allowsSending {
            cachedTransaction = ValidatedTransaction(transaction: transaction, validatedAt: Date())
        } else {
            cachedTransaction = nil
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
    var stakingCacheTimeout: TimeInterval? {
        switch self {
        case .solana: return 50
        default: return nil
        }
    }
}
