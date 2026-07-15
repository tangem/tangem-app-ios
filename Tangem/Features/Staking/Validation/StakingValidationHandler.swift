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
import TangemFoundation

/// Handles validation lifecycle for staking models.
/// Triggers validation, cancellation, and publishes state.
final class StakingValidationHandler: StakingValidationStateProvider {
    // MARK: - Properties

    private let stakingManager: StakingManager
    private let validationProvider: StakingValidationProvider
    private let stateSubject = CurrentValueSubject<StakingValidationState, Never>(.idle)
    private let syncState = OSAllocatedUnfairLock(initialState: SyncState())

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
        syncState.withLock { $0.validationTask?.cancel() }
    }

    // MARK: - Public methods

    func validate(action: StakingAction) {
        invalidate()
        stateSubject.send(.validating)
        let task = makeValidationTask(action: action)
        syncState.withLock { $0.validationTask = task }
    }

    func reset() {
        invalidate()
        syncState.withLock { $0.validationTask = nil }
        stateSubject.send(.idle)
    }

    /// Returns validated transaction if still valid, or `nil` if expired/missing.
    func validatedTransaction(for blockchain: Blockchain) -> StakingTransactionAction? {
        let cached = syncState.withLock { $0.cachedTransaction }
        guard let cached, !cached.isExpired(for: blockchain) else {
            return nil
        }
        return cached.transaction
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
        syncState.withLock {
            $0.validationTask?.cancel()
            $0.cachedTransaction = nil
        }
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

        syncState.withLock { $0.validationTask = nil }
        stateSubject.send(.validated)
    }

    @MainActor
    func handleValidationResult(_ result: StakingValidationResult) {
        guard !Task.isCancelled else { return }

        let cached: ValidatedTransaction?
        if let transaction = result.transaction, result.state.allowsSending {
            cached = ValidatedTransaction(transaction: transaction, validatedAt: Date())
        } else {
            cached = nil
        }

        syncState.withLock {
            $0.cachedTransaction = cached
            $0.validationTask = nil
        }
        stateSubject.send(result.state)
    }
}

// MARK: - Sync state

private extension StakingValidationHandler {
    struct SyncState {
        var validationTask: Task<Void, Never>?
        var cachedTransaction: ValidatedTransaction?
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
