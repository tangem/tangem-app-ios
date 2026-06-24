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
    private let decoratee: StakingTransactionSender
    private let stakingManager: StakingManager
    private let validator: StakingTransactionValidator?
    private let analyticsLogger: StakingValidationAnalyticsLogger

    private let validationStateSubject = CurrentValueSubject<StakingValidationState, Never>(.idle)
    private var validatedTransaction: StakingTransactionAction?
    private var validationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        decoratee: StakingTransactionSender,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator?,
        analyticsLogger: StakingValidationAnalyticsLogger
    ) {
        self.decoratee = decoratee
        self.stakingManager = stakingManager
        self.validator = validator
        self.analyticsLogger = analyticsLogger

        subscribeToStateChanges()
    }
}

// MARK: - StakingTransactionSender

extension StakingModelStateValidationDecorator: StakingTransactionSender {
    var state: AnyPublisher<StakingModel.State, Never> {
        decoratee.state
    }

    var target: StakingTargetInfo? {
        decoratee.target
    }

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

    func performAction() async throws -> TransactionDispatcherResult {
        guard let validatedTransaction else {
            return try await decoratee.performAction()
        }
        return try await decoratee.send(validatedTransaction)
    }

    func send(_ transaction: StakingTransactionAction) async throws -> TransactionDispatcherResult {
        try await decoratee.send(transaction)
    }
}

// MARK: - StakingValidationStateProvider

extension StakingModelStateValidationDecorator: StakingValidationStateProvider {
    var validationState: AnyPublisher<StakingValidationState, Never> {
        validationStateSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension StakingModelStateValidationDecorator {
    func subscribeToStateChanges() {
        guard validator != nil else { return }

        decoratee.state
            .sink { [weak self] state in
                self?.handleStateChange(state: state)
            }
            .store(in: &cancellables)
    }

    func handleStateChange(state: StakingModel.State) {
        guard case .readyToStake(let readyToStake) = state else {
            resetValidation()
            return
        }

        triggerValidation(readyToStake: readyToStake)
    }

    func resetValidation() {
        validationTask?.cancel()
        validationTask = nil
        validatedTransaction = nil
        validationStateSubject.send(.idle)
    }

    func triggerValidation(readyToStake: StakingModel.State.ReadyToStake) {
        guard let validator else {
            validationStateSubject.send(.idle)
            return
        }

        validationTask?.cancel()
        validatedTransaction = nil
        validationStateSubject.send(.validating)

        validationTask = Task { [weak self, stakingManager, analyticsLogger] in
            guard let self else { return }

            let target = decoratee.target
            let result = await Self.performValidation(
                readyToStake: readyToStake,
                target: target,
                stakingManager: stakingManager,
                validator: validator,
                analyticsLogger: analyticsLogger
            )

            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                self?.validatedTransaction = result.transaction
                self?.validationStateSubject.send(result.state)
            }
        }
    }

    static func performValidation(
        readyToStake: StakingModel.State.ReadyToStake,
        target: StakingTargetInfo?,
        stakingManager: StakingManager,
        validator: StakingTransactionValidator,
        analyticsLogger: StakingValidationAnalyticsLogger
    ) async -> ValidationResult {
        // Build transaction for validation
        let targetType: StakingTargetType = target.map { .target($0) } ?? .empty
        let action = StakingAction(
            amount: readyToStake.amount,
            targetType: targetType,
            type: .stake
        )

        let transactionInfo: StakingTransactionAction
        do {
            transactionInfo = try await stakingManager.transaction(action: action)
        } catch {
            // StakeKit/network errors during transaction build — allow to proceed without prebuilt transaction
            return ValidationResult(state: .validated, transaction: nil)
        }

        // Extract raw transactions for validation
        let rawTransactions = transactionInfo.transactions.compactMap { tx -> String? in
            guard case .raw(let data) = tx.unsignedTransactionData else { return nil }
            return data
        }

        guard !rawTransactions.isEmpty else {
            // No raw data to validate — block (possible blind signing attempt)
            return ValidationResult(state: .blocked, transaction: nil)
        }

        // Validate transaction
        do {
            try await validator.validate(rawTransactions)
            analyticsLogger.logSuccess()
            return ValidationResult(state: .validated, transaction: transactionInfo)
        } catch let error as StakingTransactionValidationError {
            analyticsLogger.logLocalError(error)
            // Local validation failed — transaction is suspicious, don't pass it
            return ValidationResult(state: mapToValidationState(localError: error), transaction: nil)
        } catch let error as RemoteStakingValidationError {
            analyticsLogger.logRemoteError(error)
            let state = mapToValidationState(remoteError: error)
            // For warning: pass transaction so user can proceed without rebuilding
            // For blocked: pass transaction but button is disabled anyway
            return ValidationResult(state: state, transaction: transactionInfo)
        } catch {
            // Unknown validation error — allow to proceed with built transaction
            return ValidationResult(state: .validated, transaction: transactionInfo)
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

// MARK: - ValidationResult

private extension StakingModelStateValidationDecorator {
    struct ValidationResult {
        let state: StakingValidationState
        let transaction: StakingTransactionAction?
    }
}
