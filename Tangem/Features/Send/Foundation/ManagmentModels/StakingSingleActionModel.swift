//
//  StakingSingleActionModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemStaking

protocol StakingSingleActionModelStateProvider {
    var stakingAction: StakingSingleActionModel.Action { get }

    var state: StakingSingleActionModel.State { get }
    var statePublisher: AnyPublisher<StakingSingleActionModel.State, Never> { get }
}

class StakingSingleActionModel {
    // MARK: - Data

    private let _state = CurrentValueSubject<State, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendSourceToken: SendSourceToken
    private let transactionDispatcher: TransactionDispatcher
    private let analyticsLogger: StakingSendAnalyticsLogger
    private let action: Action

    private var transactionValidator: TransactionValidator { sendSourceToken.transactionValidator }
    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }

    private var estimatedFeeTask: Task<Void, Never>?
    init(
        stakingManager: StakingManager,
        sendSourceToken: SendSourceToken,
        transactionDispatcher: TransactionDispatcher,
        analyticsLogger: StakingSendAnalyticsLogger,
        action: Action,
    ) {
        self.stakingManager = stakingManager
        self.sendSourceToken = sendSourceToken
        self.transactionDispatcher = transactionDispatcher
        self.analyticsLogger = analyticsLogger
        self.action = action

        updateState()
    }
}

// MARK: - UnstakingModelStateProvider

extension StakingSingleActionModel: StakingSingleActionModelStateProvider {
    var stakingAction: Action {
        action
    }

    var state: State {
        _state.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension StakingSingleActionModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let estimateFee = try await model.stakingManager.estimateFee(action: model.action)
                let state = model.makeState(fee: estimateFee)
                model.update(state: state)
            } catch {
                StakingLogger.error(error: error)
                model.update(state: .networkError(error))
            }
        }
    }

    func makeState(fee: Decimal) -> StakingSingleActionModel.State {
        if let error = validate(amount: action.amount, fee: fee) {
            return error
        }

        return .ready(
            fee: fee,
            stakesCount: action.targetInfo.flatMap { stakingManager.state.stakesCount(for: $0) } ?? 0
        )
    }

    func validate(amount: Decimal, fee: Decimal) -> StakingSingleActionModel.State? {
        do {
            try transactionValidator.validate(amount: makeAmount(value: .zero), fee: makeFee(value: fee))
            return nil
        } catch let error as ValidationError {
            return .validationError(error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func update(state: StakingSingleActionModel.State) {
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func mapToSendFee(_ state: State) -> LoadableTokenFee {
        switch state {
        case .loading:
            return LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .networkError(let error):
            return LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
        case .validationError(_, let fee), .ready(let fee, _):
            return LoadableTokenFee(option: .market, tokenItem: feeTokenItem, value: .success(makeFee(value: fee)))
        }
    }
}

// MARK: - Send

private extension StakingSingleActionModel {
    private func send() async throws -> TransactionDispatcherResult {
        do {
            let transaction = try await stakingManager.transaction(action: action)
            let result = try await transactionDispatcher.send(transaction: .staking(transaction))
            proceed(result: result)
            stakingManager.transactionDidSent(action: action)

            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch P2PStakingError.feeIncreased(let newFee) {
            update(state: makeState(fee: newFee))
            throw P2PStakingError.feeIncreased(newFee: newFee)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logTransactionSent(
            fee: selectedFee?.option ?? .market,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )
    }

    private func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .demoAlert,
             .userCancelled,
             .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .loadTransactionInfo,
             .actionNotSupported:
            break
        case .sendTxError(_, let error):
            analyticsLogger.logTransactionRejected(error: error)
        }
    }
}

// MARK: - SendFeeUpdater

extension StakingSingleActionModel: SendFeeUpdater {
    func updateFees() {
        updateState()
    }
}

// MARK: - SendSourceTokenInput

extension StakingSingleActionModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken {
        sendSourceToken
    }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        .just(output: sourceToken)
    }
}

// MARK: - SendSourceTokenOutput

extension StakingSingleActionModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {}
}

// MARK: - SendSourceTokenAmountInput

extension StakingSingleActionModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        let fiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }

        return .success(.init(type: .typical(crypto: action.amount, fiat: fiat)))
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        .just(output: sourceAmount)
    }
}

// MARK: - SendSourceTokenAmountOutput

extension StakingSingleActionModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in single action model")
    }
}

// MARK: - SendSummaryFeeInput

extension StakingSingleActionModel: SendSummaryFeeInput {
    var summaryFeePublisher: AnyPublisher<LoadableTokenFee, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { $0.mapToSendFee($1) }
            .eraseToAnyPublisher()
    }

    var summaryCanEditFeePublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
}

// MARK: - SendFeeInput

extension StakingSingleActionModel: SendFeeInput {
    var selectedFee: LoadableTokenFee? {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, fee in
                model.mapToSendFee(fee)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingSingleActionModel: SendFeeOutput {
    func feeDidChanged(fee: LoadableTokenFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingSingleActionModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .loading, .validationError, .networkError:
                return false
            case .ready:
                return true
            }
        }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        // Do not show any text in the unstaking flow
        .just(output: nil)
    }
}

// MARK: - StakingValidatorsInput

extension StakingSingleActionModel: StakingTargetsInput {
    var selectedTarget: StakingTargetInfo? { action.targetInfo }

    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> {
        Just(action.targetInfo).compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension StakingSingleActionModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakingSingleActionModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isLoading.eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingSingleActionModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension StakingSingleActionModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateState()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        default:
            assertionFailure("StakingModel doesn't support notification action \(action)")
        }
    }
}

// MARK: - StakingBaseDataBuilderInput

extension StakingSingleActionModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { makeAmount(value: action.amount) }

    var bsdkFee: BSDKFee? { selectedFee?.value.value }

    var isFeeIncluded: Bool { false }

    var target: StakingTargetInfo? { action.targetInfo }

    var selectedPolicy: ApprovePolicy? { nil }

    var approveViewModelInput: (any ApproveViewModelInput)? { nil }

    var stakingActionType: TangemStaking.StakingAction.ActionType? { action.type }
}

extension StakingSingleActionModel {
    typealias Action = StakingAction
    typealias State = UnstakingModel.State
}
