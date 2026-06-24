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

final class StakingModelStateValidationDecorator {
    private let decoratee: StakingModelStateProvider & SendSummaryInput
    private let targetProvider: StakingTargetsInput
    private let stakingManager: StakingManager
    private let validator: StakingTransactionValidator?
    private let analyticsLogger: StakingValidationAnalyticsLogger

    private let validationStateSubject = CurrentValueSubject<StakingValidationState, Never>(.idle)
    private var validationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        decoratee: StakingModelStateProvider & SendSummaryInput,
        targetProvider: StakingTargetsInput,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator?,
        analyticsLogger: StakingValidationAnalyticsLogger
    ) {
        self.decoratee = decoratee
        self.targetProvider = targetProvider
        self.stakingManager = stakingManager
        self.validator = validator
        self.analyticsLogger = analyticsLogger

        subscribeToStateChanges()
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
        validationStateSubject.eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryInput

extension StakingModelStateValidationDecorator: SendSummaryInput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            decoratee.isReadyToSendPublisher,
            validationStateSubject
        )
        .map { isReady, validationState in
            guard isReady else { return false }
            switch validationState {
            case .idle, .validated, .warning:
                return true
            case .validating, .blocked:
                return false
            }
        }
        .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        decoratee.summaryTransactionDataPublisher
    }
}

// MARK: - Private

private extension StakingModelStateValidationDecorator {
    func subscribeToStateChanges() {
        guard validator != nil else { return }

        Publishers.CombineLatest(
            decoratee.state,
            targetProvider.selectedTargetPublisher
        )
        .sink { [weak self] state, target in
            self?.handleStateChange(state: state, target: target)
        }
        .store(in: &cancellables)
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
        validationStateSubject.send(.idle)
    }

    func triggerValidation(readyToStake: StakingModel.State.ReadyToStake, target: StakingTargetInfo) {
        guard let validator else {
            validationStateSubject.send(.idle)
            return
        }

        validationTask?.cancel()
        validationStateSubject.send(.validating)

        validationTask = Task { [weak self, stakingManager, analyticsLogger] in
            let result = await Self.performValidation(
                readyToStake: readyToStake,
                target: target,
                stakingManager: stakingManager,
                validator: validator,
                analyticsLogger: analyticsLogger
            )

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                self?.validationStateSubject.send(result)
            }
        }
    }

    static func performValidation(
        readyToStake: StakingModel.State.ReadyToStake,
        target: StakingTargetInfo,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator,
        analyticsLogger: StakingValidationAnalyticsLogger
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

            analyticsLogger.logSuccess()
            return .validated
        } catch let error as StakingTransactionValidationError {
            analyticsLogger.logLocalError(error)
            return mapToValidationState(localError: error)
        } catch let error as RemoteStakingValidationError {
            analyticsLogger.logRemoteError(error)
            return mapToValidationState(remoteError: error)
        } catch {
            return .validated
        }
    }

    static func mapToValidationState(localError: StakingTransactionValidationError) -> StakingValidationState {
        switch localError {
        case .emptyOrMalformedData, .notAStakingTransaction:
            .blocked
        }
    }

    static func mapToValidationState(remoteError: RemoteStakingValidationError) -> StakingValidationState {
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
