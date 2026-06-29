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

/// Handles validation lifecycle for staking models.
/// Triggers validation, cancellation, and publishes state.
final class StakingValidationHandler: StakingValidationStateProvider {
    // MARK: - Properties

    private let stakingManager: StakingManager
    private let validationProvider: StakingValidationProvider
    private let stateSubject = CurrentValueSubject<StakingValidationState, Never>(.idle)

    private var validationTask: Task<Void, Never>?

    private(set) var validatedTransaction: StakingTransactionAction?

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

        validatedTransaction = result.transaction
        stateSubject.send(result.state)
        validationTask = nil
    }
}
