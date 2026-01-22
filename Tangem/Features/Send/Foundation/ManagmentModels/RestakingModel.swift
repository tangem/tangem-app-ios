//
//  RestakingModel.swift
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

protocol RestakingModelStateProvider {
    var stakingAction: RestakingModel.Action { get }

    var state: RestakingModel.State { get }
    var statePublisher: AnyPublisher<RestakingModel.State, Never> { get }
}

class RestakingModel {
    // MARK: - Data

    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)
    private let _state = CurrentValueSubject<State, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let action: Action
    private let sendSourceToken: SendSourceToken
    private let transactionDispatcher: TransactionDispatcher
    private let sendAmountValidator: SendAmountValidator
    private let analyticsLogger: StakingSendAnalyticsLogger

    private var transactionValidator: TransactionValidator { sendSourceToken.transactionValidator }
    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        action: Action,
        sendSourceToken: SendSourceToken,
        transactionDispatcher: TransactionDispatcher,
        sendAmountValidator: SendAmountValidator,
        analyticsLogger: StakingSendAnalyticsLogger,
    ) {
        self.stakingManager = stakingManager
        self.action = action
        self.sendSourceToken = sendSourceToken
        self.transactionDispatcher = transactionDispatcher
        self.sendAmountValidator = sendAmountValidator
        self.analyticsLogger = analyticsLogger

        bind()
    }
}

// MARK: - RestakingModelStateProvider

extension RestakingModel: RestakingModelStateProvider {
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

private extension RestakingModel {
    func bind() {
        _selectedValidator
            .removeDuplicates()
            .compactMap { $0.value }
            .first()
            .withWeakCaptureOf(self)
            .sink { model, _ in
                model.updateState()
            }
            .store(in: &bag)
    }

    func updateState() {
        guard let validator = _selectedValidator.value.value else {
            return
        }

        do {
            try validateMinimumStakingAmountRequirement()
        } catch {
            update(state: .stakingValidationError(error))
            return
        }

        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let state = try await model.state(amount: model.action.amount, validator: validator)
                model.update(state: state)
            } catch is CancellationError {
                // Do nothing
            } catch {
                AppLogger.error(error: error)
                model.update(state: .networkError(error))
            }
        }
    }

    func state(amount: Decimal, validator: ValidatorInfo) async throws -> RestakingModel.State {
        let estimateFee = try await stakingManager.estimateFee(
            action: StakingAction(amount: amount, validatorType: .validator(validator), type: action.type)
        )

        if let error = validate(amount: action.amount, fee: estimateFee) {
            return error
        }

        return .ready(fee: estimateFee)
    }

    func validateMinimumStakingAmountRequirement() throws(StakingValidationError) {
        do {
            try sendAmountValidator.validate(amount: action.amount)
        } catch let error as StakingValidationError {
            AppLogger.error(error: error)
            throw error
        } catch {
            AppLogger.error(error: error)
        }
    }

    func validate(amount: Decimal, fee: Decimal) -> RestakingModel.State? {
        do {
            try transactionValidator.validate(amount: makeAmount(value: .zero), fee: makeFee(value: fee))
            return nil
        } catch let error as ValidationError {
            return .validationError(error, fee: fee)
        } catch CardanoError.feeParametersNotFound {
            return nil
        } catch {
            return .networkError(error)
        }
    }

    func update(state: RestakingModel.State) {
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func mapToSendFee(_ state: State) -> SendFee {
        switch state {
        case .loading:
            return SendFee(option: .market, value: .loading)
        case .networkError(let error):
            return SendFee(option: .market, value: .failedToLoad(error: error))
        case .stakingValidationError(let error):
            return SendFee(option: .market, value: .failedToLoad(error: error))
        case .validationError(_, let fee), .ready(let fee):
            return SendFee(option: .market, value: .loaded(makeFee(value: fee)))
        }
    }
}

// MARK: - Send

private extension RestakingModel {
    private func send() async throws -> TransactionDispatcherResult {
        guard let validator = _selectedValidator.value.value else {
            throw StakingModelError.validatorNotFound
        }

        let action = StakingAction(
            amount: action.amount,
            validatorType: .validator(validator),
            type: action.type
        )

        do {
            let transaction = try await stakingManager.transaction(action: action)
            let result = try await transactionDispatcher.send(transaction: .staking(transaction))
            proceed(result: result)
            stakingManager.transactionDidSent(action: action)

            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logTransactionSent(fee: selectedFee, signerType: result.signerType, currentProviderHost: result.currentHost)
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

// MARK: - SendFeeProvider

extension RestakingModel: SendFeeProvider {
    var feeOptions: [FeeOption] { [.market] }

    var fees: TangemFoundation.LoadingResult<[SendFee], any Error> {
        .success([mapToSendFee(_state.value)])
    }

    var feesPublisher: AnyPublisher<TangemFoundation.LoadingResult<[SendFee], any Error>, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { .success([$0.mapToSendFee($1)]) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        updateState()
    }
}

// MARK: - SendSourceTokenInput

extension RestakingModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken {
        sendSourceToken
    }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        .just(output: sourceToken)
    }
}

// MARK: - SendSourceTokenOutput

extension RestakingModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {}
}

// MARK: - SendSourceTokenAmountInput

extension RestakingModel: SendSourceTokenAmountInput {
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

extension RestakingModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in restaking")
    }
}

// MARK: - StakingValidatorsInput

extension RestakingModel: StakingValidatorsInput {
    var selectedValidator: ValidatorInfo? { _selectedValidator.value.value }
    var selectedValidatorPublisher: AnyPublisher<TangemStaking.ValidatorInfo, Never> {
        _selectedValidator.compactMap { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - StakingValidatorsOutput

extension RestakingModel: StakingValidatorsOutput {
    func userDidSelected(validator: TangemStaking.ValidatorInfo) {
        _selectedValidator.send(.loaded(validator))
    }
}

// MARK: - SendFeeInput

extension RestakingModel: SendFeeInput {
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
}

// MARK: - SendFeeOutput

extension RestakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension RestakingModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .loading, .validationError, .networkError, .stakingValidationError:
                return false
            case .ready:
                return true
            }
        }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        // Do not show any text in the restaking flow
        .just(output: nil)
    }
}

// MARK: - SendFinishInput

extension RestakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension RestakingModel: SendBaseInput, SendBaseOutput {
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

extension RestakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension RestakingModel: NotificationTapDelegate {
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

extension RestakingModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { makeAmount(value: action.amount) }

    var bsdkFee: BlockchainSdk.Fee? { selectedFee.value.value }

    var isFeeIncluded: Bool { false }

    var stakingActionType: TangemStaking.StakingAction.ActionType? { stakingAction.type }

    var selectedPolicy: ApprovePolicy? { nil }

    var approveViewModelInput: (any ApproveViewModelInput)? { nil }

    var validator: ValidatorInfo? { action.validatorInfo }
}

extension RestakingModel {
    typealias Action = StakingAction

    enum State {
        case loading
        case ready(fee: Decimal)
        case validationError(ValidationError, fee: Decimal)
        case networkError(Error)
        case stakingValidationError(StakingValidationError)
    }
}
