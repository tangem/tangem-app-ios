//
//  UnstakingModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk

protocol UnstakingModelStateProvider {
    var state: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _state = CurrentValueSubject<State?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let balanceInfo: StakingBalanceInfo
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        balanceInfo: StakingBalanceInfo,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.balanceInfo = balanceInfo
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem
        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

        updateState()
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
    var state: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension UnstakingModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                try model.update(state: .loading)
                try await model.update(state: .loaded(model.fee()))
            } catch {
                AppLog.shared.error(error)
                try? model.update(state: .failedToLoad(error: error))
            }
        }
    }

    func update(state: LoadingValue<Decimal>) throws {
        let action = try stakingAction()

        switch action.type {
        case .unstake:
            _state.send(.unstaking(fee: state))
        case .pending(.withdraw):
            _state.send(.withdraw(fee: state))
        case .pending(.claimRewards), .pending(.restakeRewards):
            _state.send(.claim(fee: state))
        case .stake:
            assertionFailure("UnstakingModel doesn't support actionType: \(action.type)")
        }
    }

    func fee() async throws -> Decimal {
        let action = try stakingAction()

        return try await stakingManager.estimateFee(action: action)
    }

    func mapToSendFee(_ state: State?) -> SendFee {
        switch state {
        case .none:
            return SendFee(option: .market, value: .failedToLoad(error: CommonError.noData))
        case .unstaking(let loadingValue), .withdraw(let loadingValue), .claim(let loadingValue):
            let newValue = loadingValue.mapValue { value in
                Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
            }

            return SendFee(option: .market, value: newValue)
        }
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func stakingAction() throws -> StakingAction {
        switch balanceInfo.balanceType {
        case .warmup, .unbonding:
            throw UnstakingModelError.notSupported(
                "UnstakingModel doesn't support balanceType: \(balanceInfo.balanceType)"
            )
        case .active:
            return StakingAction(
                amount: balanceInfo.amount,
                validator: balanceInfo.validatorAddress,
                type: .unstake
            )
        case .withdraw:
            guard case .withdraw(let passthrough) = balanceInfo.actions.first else {
                throw UnstakingModelError.passthroughNotFound
            }

            return StakingAction(
                amount: balanceInfo.amount,
                validator: balanceInfo.validatorAddress,
                type: .pending(.withdraw(passthrough: passthrough))
            )

        case .rewards:
            guard case .claimRewards(let passthrough) = balanceInfo.actions.first else {
                throw UnstakingModelError.passthroughNotFound
            }

            return StakingAction(
                amount: balanceInfo.amount,
                validator: balanceInfo.validatorAddress,
                type: .pending(.claimRewards(passthrough: passthrough))
            )
        }
    }

    private func send() async throws -> SendTransactionDispatcherResult {
        let action = try stakingAction()
        let transactionInfo = try await stakingManager.transaction(action: action)
        let transaction = stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: action.amount)

        do {
            let result = try await sendTransactionDispatcher.send(
                transaction: .staking(transactionId: transactionInfo.id, transaction: transaction)
            )
            proceed(result: result)
            return result
        } catch let error as SendTransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw error
        }
    }

    private func proceed(result: SendTransactionDispatcherResult) {
        _transactionTime.send(Date())
    }

    private func proceed(error: SendTransactionDispatcherResult.Error) {
        switch error {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .stakingUnsupported,
             .demoAlert,
             .userCancelled,
             .sendTxError:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}

// MARK: - SendFeeLoader

extension UnstakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
    var amount: SendAmount? {
        let fiat = amountTokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balanceInfo.amount, currencyId: $0)
        }

        return .init(type: .typical(crypto: balanceInfo.amount, fiat: fiat))
    }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        Just(amount).eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension UnstakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in unstaking")
    }
}

// MARK: - SendFeeInput

extension UnstakingModel: SendFeeInput {
    var selectedFee: SendFee {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, fee in
                model.mapToSendFee(fee)
            }
            .eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        .just(output: [selectedFee])
    }

    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        amountPublisher.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        assertionFailure("We don't have destination in staking")
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension UnstakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension UnstakingModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { $0?.fee != nil }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        // Do not show any text in the unstaking flow
        .just(output: nil)
    }
}

// MARK: - SendFinishInput

extension UnstakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension UnstakingModel: SendBaseInput, SendBaseOutput {
    var isFeeIncluded: Bool { false }

    var isLoading: AnyPublisher<Bool, Never> {
        _isLoading.eraseToAnyPublisher()
    }

    func sendTransaction() async throws -> SendTransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

extension UnstakingModel {
    enum State: Hashable {
        case unstaking(fee: LoadingValue<Decimal>)
        case withdraw(fee: LoadingValue<Decimal>)
        case claim(fee: LoadingValue<Decimal>)

        var fee: Decimal? {
            switch self {
            case .unstaking(.loaded(let fee)): fee
            case .withdraw(.loaded(let fee)): fee
            case .claim(.loaded(let fee)): fee
            default: nil
            }
        }
    }
}

enum UnstakingModelError: Error {
    case passthroughNotFound
    case notSupported(String)
}
