//
//  StakingModelStateValidationDecorator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import BlockchainSdk

/// Decorator that wraps StakingModelStateProvider and adds transaction validation.
/// Follows OCP: proxies state unchanged, publishes validation result separately.
final class StakingModelStateValidationDecorator {
    private let decoratee: StakingModelStateProvider
    private let targetProvider: StakingTargetsInput
    private let stakingManager: StakingManager
    private let validator: StakingTransactionValidator?

    private let _validationState = CurrentValueSubject<StakingValidationState, Never>(.idle)
    private var validationTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(
        decoratee: StakingModelStateProvider,
        targetProvider: StakingTargetsInput,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator?
    ) {
        self.decoratee = decoratee
        self.targetProvider = targetProvider
        self.stakingManager = stakingManager
        self.validator = validator

        bind()
    }
}

// MARK: - StakingModelStateProvider

extension StakingModelStateValidationDecorator: StakingModelStateProvider {
    var state: AnyPublisher<StakingModel.State, Never> {
        decoratee.state
    }
}

// MARK: - StakingValidationStateProvider

extension StakingModelStateValidationDecorator: StakingValidationStateProvider {
    var validationState: AnyPublisher<StakingValidationState, Never> {
        _validationState.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension StakingModelStateValidationDecorator {
    func bind() {
        guard validator != nil else { return }

        Publishers.CombineLatest(
            decoratee.state,
            targetProvider.selectedTargetPublisher
        )
        .sink { [weak self] state, target in
            self?.handleStateChange(state: state, target: target)
        }
        .store(in: &bag)
    }

    func handleStateChange(state: StakingModel.State, target: StakingTargetInfo) {
        guard case .readyToStake(let readyToStake) = state else {
            resetValidation()
            return
        }

        triggerValidation(readyToStake: readyToStake, target: target)
    }

    func resetValidation() {
        validationTask?.cancel()
        validationTask = nil
        _validationState.send(.idle)
    }

    func triggerValidation(readyToStake: StakingModel.State.ReadyToStake, target: StakingTargetInfo) {
        guard let validator else {
            _validationState.send(.idle)
            return
        }

        validationTask?.cancel()
        _validationState.send(.validating)

        validationTask = Task { [weak self, stakingManager] in
            let result = await Self.performValidation(
                readyToStake: readyToStake,
                target: target,
                stakingManager: stakingManager,
                validator: validator
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?._validationState.send(result)
            }
        }
    }

    static func performValidation(
        readyToStake: StakingModel.State.ReadyToStake,
        target: StakingTargetInfo,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator
    ) async -> StakingValidationState {
        do {
            let action = StakingAction(
                amount: readyToStake.amount,
                targetType: .target(target),
                type: .stake
            )

            let transactionInfo = try await stakingManager.transaction(action: action)

            let rawTransactions = transactionInfo.transactions.compactMap { tx -> String? in
                guard case .raw(let data) = tx.unsignedTransactionData else { return nil }
                return data
            }

            guard !rawTransactions.isEmpty else {
                return .blocked
            }

            try await validator.validate(rawTransactions)
            return .validated
        } catch let error as StakingTransactionValidationError {
            return mapToValidationState(error: error)
        } catch {
            return .validated
        }
    }

    static func mapToValidationState(error: StakingTransactionValidationError) -> StakingValidationState {
        switch error {
        case .blockaidWarning: .warning
        case .blockaidMalicious: .blocked
        default: .validated
        }
    }
}
