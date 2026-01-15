//
//  StakingModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import BlockchainSdk
import TangemFoundation
import struct TangemUI.TokenIconInfo

protocol StakingModelStateProvider {
    var state: AnyPublisher<StakingModel.State, Never> { get }
}

final class StakingModel {
    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedTarget = CurrentValueSubject<LoadingResult<StakingTargetInfo, Never>, Never>(.loading)
    private let _state = CurrentValueSubject<State?, Never>(.none)
    private let _approvePolicy = CurrentValueSubject<ApprovePolicy, Never>(.unlimited)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?
    var amountExternalUpdater: SendAmountExternalUpdater?

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendSourceToken: SendSourceToken
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let stakingTransactionDispatcher: TransactionDispatcher
    private let transactionDispatcher: TransactionDispatcher
    private let allowanceService: AllowanceService?
    private let analyticsLogger: StakingSendAnalyticsLogger
    private let accountInitializationService: BlockchainAccountInitializationService?
    private let minimalBalanceProvider: MinimalBalanceProvider?

    private var timerTask: Task<Void, Error>?
    private var estimatedFeeTask: Task<Void, Never>?
    private var accountInitializationFee: Fee?

    private var transactionCreator: TransactionCreator { sendSourceToken.transactionCreator }
    private var transactionValidator: TransactionValidator { sendSourceToken.transactionValidator }
    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }
    private var tokenIconInfo: TokenIconInfo { sendSourceToken.tokenIconInfo }

    init(
        stakingManager: StakingManager,
        sendSourceToken: SendSourceToken,
        feeIncludedCalculator: FeeIncludedCalculator,
        stakingTransactionDispatcher: TransactionDispatcher,
        transactionDispatcher: TransactionDispatcher,
        allowanceService: AllowanceService?,
        analyticsLogger: StakingSendAnalyticsLogger,
        accountInitializationService: BlockchainAccountInitializationService?,
        minimalBalanceProvider: MinimalBalanceProvider?,
    ) {
        self.stakingManager = stakingManager
        self.sendSourceToken = sendSourceToken
        self.feeIncludedCalculator = feeIncludedCalculator
        self.stakingTransactionDispatcher = stakingTransactionDispatcher
        self.transactionDispatcher = transactionDispatcher
        self.allowanceService = allowanceService
        self.analyticsLogger = analyticsLogger
        self.accountInitializationService = accountInitializationService
        self.minimalBalanceProvider = minimalBalanceProvider
    }
}

// MARK: - StakingModelStateProvider

extension StakingModel: StakingModelStateProvider {
    var state: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Bind

private extension StakingModel {
    func updateState() {
        guard let currentAmount = _amount.value?.crypto,
              let target = _selectedTarget.value.value else {
            return
        }

        // temp hack to prevent error on max amount staking after account initialization
        let amount = currentAmount - (accountInitializationFee?.amount.value ?? .zero)

        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let newState = try await model.state(amount: amount, target: target, approvePolicy: model._approvePolicy.value)
                model.update(state: newState)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                model.update(state: .networkError(error))
            }
        }
    }

    func state(amount: Decimal, target: StakingTargetInfo, approvePolicy: ApprovePolicy) async throws -> StakingModel.State {
        if let allowanceState = try await allowanceState(amount: amount, approvePolicy: approvePolicy) {
            switch allowanceState {
            case .permissionRequired(let approveData):
                stopTimer()

                if let validateError = validate(amount: amount, fee: approveData.fee.amount.value) {
                    return validateError
                }

                return .readyToApprove(approveData: approveData)

            case .approveTransactionInProgress:
                return try await .approveTransactionInProgress(
                    stakingFee: estimateFee(amount: amount, target: target)
                )

            case .enoughAllowance:
                stopTimer()
            }
        }

        let fee = try await estimateFee(amount: amount, target: target)

        if let accountInitializationService,
           try await accountInitializationService.isAccountInitialized() == false {
            analyticsLogger.logNoticeUninitializedAddress()

            let initializationFee = try await accountInitializationService.estimateInitializationFee()
            return .blockchainAccountInitializationRequired(
                initializationFee: initializationFee,
                transactionFee: makeFee(value: fee)
            )
        }

        return makeState(amount: amount, fee: fee, target: target)
    }

    func validate(amount: Decimal, fee: Decimal) -> StakingModel.State? {
        do {
            let amount = makeAmount(value: amount)
            let fee = makeFee(value: fee)

            try transactionValidator.validate(amount: amount, fee: fee)

            return nil
        } catch let error as ValidationError {
            return .validationError(error: error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func estimateFee(amount: Decimal, target: StakingTargetInfo) async throws -> Decimal {
        try await stakingManager.estimateFee(
            action: StakingAction(amount: amount, targetType: .target(target), type: .stake)
        )
    }

    func allowanceState(amount: Decimal, approvePolicy: ApprovePolicy) async throws -> AllowanceState? {
        guard let allowanceService, let spender = stakingManager.allowanceAddress else {
            return nil
        }

        return try await allowanceService
            .allowanceState(amount: amount, spender: spender, approvePolicy: approvePolicy)
    }

    func mapToSendFee(_ state: State?) -> TokenFee {
        switch state {
        case .none, .loading:
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .readyToApprove(let approveData):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(approveData.fee))
        case .readyToStake(let readyToStake):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(makeFee(value: readyToStake.fee)))
        case .approveTransactionInProgress(let fee),
             .validationError(_, let fee):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(makeFee(value: fee)))
        case .networkError(let error):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
        case .blockchainAccountInitializationRequired(_, let transactionFee):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(transactionFee))
        case .blockchainAccountInitializationInProgress:
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(StakingModelError.accountIsNotInitialized))
        }
    }

    func update(state: State) {
        log("update state: \(state)")
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    private func makeState(amount: Decimal, fee: Decimal, target: StakingTargetInfo) -> State {
        let includeFee = feeIncludedCalculator.shouldIncludeFee(makeFee(value: fee), into: makeAmount(value: amount))
        let newAmount = includeFee ? amount - fee : amount
        _isFeeIncluded.send(includeFee)

        if let validateError = validate(amount: newAmount, fee: fee) {
            return validateError
        }

        let balances = stakingManager.balances ?? []
        let hasPreviousStakeOnDifferentValidator = balances.contains { balance in
            balance.balanceType == .active && balance.targetType.target != target
        }

        let increasedFee = fee * Constants.reduceAmountMultiplier
        let minBalance = minimalBalanceProvider?.minimalBalance() ?? .zero
        let amountToReduce = increasedFee + minBalance

        return .readyToStake(
            .init(
                amount: newAmount,
                fee: fee,
                isFeeIncluded: includeFee,
                stakeOnDifferentValidator: hasPreviousStakeOnDifferentValidator,
                amountToReduce: includeFee ? amountToReduce : nil
            )
        )
    }

    func log(_ message: String) {
        StakingLogger.info(self, message)
    }
}

// MARK: - Timer

private extension StakingModel {
    func restartTimer() {
        log("Restart timer")
        timerTask?.cancel()
        timerTask = runTask(in: self) { model in
            try Task.checkCancellation()

            try await Task.sleep(for: .seconds(5))

            model.log("timer realised")
            model.updateState()

            try Task.checkCancellation()

            model.restartTimer()
        }
    }

    func stopTimer() {
        log("Stop timer")
        timerTask?.cancel()
        timerTask = nil
    }
}

// MARK: - Send

private extension StakingModel {
    private func send() async throws -> TransactionDispatcherResult {
        guard case .readyToStake(let readyToStake) = _state.value else {
            throw StakingModelError.readyToStakeNotFound
        }

        guard let target = _selectedTarget.value.value else {
            throw StakingModelError.targetNotFound
        }

        do {
            let action = StakingAction(
                amount: readyToStake.amount,
                targetType: .target(target),
                type: .stake
            )

            let transactionInfo = try await stakingManager.transaction(action: action)
            let transactionsFee = transactionInfo.transactions.reduce(Decimal.zero) { $0 + $1.fee }
            if readyToStake.isFeeIncluded,
               transactionsFee > readyToStake.fee,
               let amount = _amount.value?.crypto {
                update(state: makeState(amount: amount, fee: transactionsFee, target: target))
                throw TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased
            }
            let result = try await stakingTransactionDispatcher.send(transaction: .staking(transactionInfo))
            stakingManager.transactionDidSent(action: action)

            proceed(result: result)
            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch P2PStakingError.feeIncreased(let newFee) {
            update(state: makeState(amount: readyToStake.amount, fee: newFee, target: target))
            throw P2PStakingError.feeIncreased(newFee: newFee)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logTransactionSent(
            amount: _amount.value,
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

// MARK: - SendFeeProvider

extension StakingModel: SendFeeProvider {
    var feeOptions: [FeeOption] { [.market] }

    var fees: [TokenFee] {
        [mapToSendFee(_state.value)]
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        _state
            .withWeakCaptureOf(self)
            .map { [$0.mapToSendFee($1)] }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        updateState()
    }
}

// MARK: - SendSourceTokenInput

extension StakingModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken {
        sendSourceToken
    }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        .just(output: sourceToken)
    }
}

// MARK: - SendSourceTokenOutput

extension StakingModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {}
}

// MARK: - SendSourceTokenAmountInput

extension StakingModel: SendSourceTokenAmountInput {
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

extension StakingModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - StakingValidatorsInput

extension StakingModel: StakingTargetsInput {
    var selectedTarget: StakingTargetInfo? { _selectedTarget.value.value }
    var selectedTargetPublisher: AnyPublisher<TangemStaking.StakingTargetInfo, Never> {
        _selectedTarget.compactMap { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - StakingValidatorsOutput

extension StakingModel: StakingTargetsOutput {
    func userDidSelect(target: TangemStaking.StakingTargetInfo) {
        _selectedTarget.send(.success(target))
    }
}

// MARK: - SendFeeInput

extension StakingModel: SendFeeInput {
    var selectedFee: TokenFee? {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, state in
                model.mapToSendFee(state)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingModel: SendFeeOutput {
    func feeDidChanged(fee: TokenFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .readyToStake, .readyToApprove:
                return true
            case .none, .loading, .approveTransactionInProgress,
                 .validationError, .networkError,
                 .blockchainAccountInitializationRequired, .blockchainAccountInitializationInProgress:
                return false
            }
        }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers.CombineLatest(_amount, stakingManager.statePublisher)
            .map { amount, state in
                guard let amount, let schedule = state.yieldInfo?.rewardScheduleType else {
                    return nil
                }

                return .staking(amount: amount, schedule: schedule)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension StakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakingModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            stakingManager.statePublisher.map { $0.isLoading },
            _isLoading
        )
        .eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension StakingModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateState()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .activate:
            guard let accountInitializationService,
                  case .blockchainAccountInitializationRequired(let initializationFee, _) = _state.value else { return }

            let viewModel = BlockchainAccountInitializationViewModel(
                accountInitializationService: accountInitializationService,
                transactionDispatcher: transactionDispatcher,
                tokenItem: tokenItem,
                fee: initializationFee,
                feeTokenItem: feeTokenItem,
                tokenIconInfo: tokenIconInfo,
                onStartInitialization: { [weak self] in
                    self?.update(state: .blockchainAccountInitializationInProgress)
                },
                onInitialized: { [weak self] in
                    self?.accountInitializationFee = initializationFee
                    self?.updateState()
                }
            )

            router?.openAccountInitializationFlow(viewModel: viewModel)
        case .reduceAmountBy(let amountToReduce, _, _):
            guard let oldAmount = sourceAmount.value?.main else {
                return
            }

            let newAmount = oldAmount - amountToReduce
            amountExternalUpdater?.externalUpdate(amount: newAmount)
            updateState()
        default:
            assertionFailure("StakingModel doesn't support notification action \(action)")
        }
    }
}

// MARK: - ApproveViewModelInput

extension StakingModel: ApproveViewModelInput {
    var approveFeeValue: LoadingResult<Fee, Error> {
        selectedFee?.value ?? .loading
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingResult<Fee, Error>, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, state in
                model.mapToSendFee(state).value
            }
            .eraseToAnyPublisher()
    }

    func updateApprovePolicy(policy: ApprovePolicy) {
        _approvePolicy.send(policy)
        updateState()
    }

    func sendApproveTransaction() async throws {
        guard case .readyToApprove(let approveData) = _state.value else {
            throw StakingModelError.approveDataNotFound
        }

        guard let allowanceService else {
            throw StakingModelError.allowanceServiceNotFound
        }

        _ = try await allowanceService.sendApproveTransaction(data: approveData)
        updateState()

        // Setup timer for autoupdate
        restartTimer()
    }
}

// MARK: - StakingBaseDataBuilderInput

extension StakingModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { _amount.value?.crypto.map { makeAmount(value: $0) } }

    var bsdkFee: BSDKFee? { selectedFee?.value.value }

    var isFeeIncluded: Bool { _isFeeIncluded.value }

    var selectedPolicy: ApprovePolicy? { _approvePolicy.value }

    var approveViewModelInput: (any ApproveViewModelInput)? { self }

    var stakingActionType: StakingAction.ActionType? { .stake }

    var target: StakingTargetInfo? { _selectedTarget.value.value }
}

extension StakingModel {
    enum State {
        case loading
        case blockchainAccountInitializationRequired(initializationFee: Fee, transactionFee: Fee)
        case blockchainAccountInitializationInProgress
        case readyToApprove(approveData: ApproveTransactionData)
        case approveTransactionInProgress(stakingFee: Decimal)
        case readyToStake(ReadyToStake)
        case validationError(error: ValidationError, fee: Decimal)
        case networkError(Error)

        var fee: Decimal? {
            switch self {
            case .readyToApprove(let requiredApprove): requiredApprove.fee.amount.value
            case .approveTransactionInProgress(let fee): fee
            case .readyToStake(let model): model.fee
            case .loading, .validationError, .networkError,
                 .blockchainAccountInitializationRequired, .blockchainAccountInitializationInProgress: nil
            }
        }

        struct ReadyToStake {
            let amount: Decimal
            let fee: Decimal
            let isFeeIncluded: Bool
            let stakeOnDifferentValidator: Bool
            let amountToReduce: Decimal?
        }
    }
}

enum StakingModelError: String, Hashable, LocalizedError {
    case readyToStakeNotFound
    case targetNotFound
    case allowanceServiceNotFound
    case approveDataNotFound
    case accountIsNotInitialized

    var errorDescription: String? { rawValue }
}

// MARK: - CustomStringConvertible

extension StakingModel: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

private extension StakingModel {
    enum Constants {
        static let reduceAmountMultiplier = Decimal(string: "3")!
    }
}
