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
import TangemFoundation

protocol UnstakingModelStateProvider {
    var stakedBalance: Decimal { get }
    var stakingAction: UnstakingModel.Action { get }

    var state: UnstakingModel.State { get }
    var statePublisher: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _amount: CurrentValueSubject<SendAmount?, Never>
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
    private let initialAction: Action

    private var transactionValidator: TransactionValidator { sendSourceToken.transactionValidator }
    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }

    private var estimatedFeeTask: Task<Void, Never>?
    init(
        stakingManager: StakingManager,
        sendSourceToken: SendSourceToken,
        transactionDispatcher: TransactionDispatcher,
        analyticsLogger: StakingSendAnalyticsLogger,
        action: Action
    ) {
        self.stakingManager = stakingManager
        self.sendSourceToken = sendSourceToken
        self.transactionDispatcher = transactionDispatcher
        self.analyticsLogger = analyticsLogger
        initialAction = action

        let fiat = sendSourceToken.tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }

        _amount = CurrentValueSubject(SendAmount(type: .typical(crypto: action.amount, fiat: fiat)))
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
    var stakedBalance: Decimal {
        initialAction.amount
    }

    var stakingAction: Action {
        let amount = _amount.value?.crypto ?? initialAction.amount
        return Action(amount: amount, targetType: initialAction.targetType, type: initialAction.type)
    }

    var state: State {
        _state.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension UnstakingModel {
    func updateState() {
        guard let amount = _amount.value?.crypto else { return }

        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let estimateFee = try await model.stakingManager.estimateFee(action: model.stakingAction)
                let state = model.makeState(amount: amount, fee: estimateFee)
                model.update(state: state)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                StakingLogger.error(error: error)
                model.update(state: .networkError(error))
            }
        }
    }

    func makeState(amount: Decimal, fee: Decimal) -> UnstakingModel.State {
        if let error = validate(amount: amount, fee: fee) {
            return error
        }

        return .ready(
            fee: fee,
            stakesCount: stakingAction.targetInfo.flatMap { stakingManager.state.stakesCount(for: $0) } ?? 0
        )
    }

    func validate(amount: Decimal, fee: Decimal) -> UnstakingModel.State? {
        do {
            try transactionValidator.validate(amount: makeAmount(value: .zero), fee: makeFee(value: fee))
            return nil
        } catch let error as ValidationError {
            return .validationError(error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func update(state: UnstakingModel.State) {
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func mapToSendFee(_ state: State) -> TokenFee {
        switch state {
        case .loading:
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .networkError(let error):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
        case .validationError(_, let fee), .ready(let fee, _):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(makeFee(value: fee)))
        }
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func send() async throws -> TransactionDispatcherResult {
        guard let amount = sourceAmount.value?.crypto else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        do {
            let transaction = try await stakingManager.transaction(action: stakingAction)
            let result = try await transactionDispatcher.send(transaction: .staking(transaction))
            proceed(result: result)
            stakingManager.transactionDidSent(action: stakingAction)

            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch P2PStakingError.feeIncreased(let newFee) {
            update(state: makeState(amount: amount, fee: newFee))
            throw P2PStakingError.feeIncreased(newFee: newFee)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logTransactionSent(
            fee: .market,
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

extension UnstakingModel: SendFeeUpdater {
    func updateFees() {
        updateState()
    }
}

// MARK: - SendSourceTokenInput

extension UnstakingModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken {
        sendSourceToken
    }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        .just(output: sourceToken)
    }
}

// MARK: - SendSourceTokenOutput

extension UnstakingModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {}
}

// MARK: - SendSourceTokenAmountInput

extension UnstakingModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        switch _amount.value {
        case .none: .failure(SendAmountError.noAmount)
        case .some(let amount): .success(amount)
        }
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _amount.map { amount in
            switch amount {
            case .none: .failure(SendAmountError.noAmount)
            case .some(let amount): .success(amount)
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension UnstakingModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendFeeInput

extension UnstakingModel: SendFeeInput {
    var selectedFee: TokenFee? {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { $0.mapToSendFee($1) }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension UnstakingModel: SendSummaryInput, SendSummaryOutput {
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

// MARK: - SendFinishInput

extension UnstakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - StakingValidatorsInput

extension UnstakingModel: StakingTargetsInput {
    var selectedTarget: StakingTargetInfo? { stakingAction.targetInfo }

    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> {
        Just(stakingAction.targetInfo).compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension UnstakingModel: SendBaseInput, SendBaseOutput {
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

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension UnstakingModel: NotificationTapDelegate {
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

extension UnstakingModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { _amount.value?.crypto.flatMap { makeAmount(value: $0) } }

    var bsdkFee: BSDKFee? { selectedFee?.value.value }

    var isFeeIncluded: Bool { false }

    var target: StakingTargetInfo? { initialAction.targetInfo }

    var selectedPolicy: ApprovePolicy? { nil }

    var approveViewModelInput: (any ApproveViewModelInput)? { nil }

    var stakingActionType: TangemStaking.StakingAction.ActionType? { .unstake }
}

extension UnstakingModel {
    typealias Action = StakingAction

    enum State {
        case loading
        case ready(fee: Decimal, stakesCount: Int?)
        case validationError(ValidationError, fee: Decimal)
        case networkError(Error)
    }
}

extension UnstakingModel {
    var isPartialUnstakeAllowed: Bool {
        guard case .target(let targetInfo) = initialAction.targetType else {
            return false
        }
        // disable partial unstake for disabled validators,
        // preferred == false means it's disabled in admin tool
        guard targetInfo.preferred else { return false }

        return switch tokenItem.blockchain {
        case .ton, .cardano: false // ton and cardano do not support partial unstake
        default: true
        }
    }
}
