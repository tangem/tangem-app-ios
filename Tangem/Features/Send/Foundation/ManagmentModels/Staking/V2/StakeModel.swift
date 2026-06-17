//
//  StakeModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import struct TangemUI.TokenIconInfo

protocol StakeModelStateProvider {
    var state: StakeFlowState { get }
    var statePublisher: AnyPublisher<StakeFlowState, Never> { get }
    /// The action as currently parameterized (entered amount + selected target). Notifications key on it.
    var stakingAction: StakingAction { get }
    /// The amount staked in the position this flow acts on (the action's initial amount).
    var stakedBalance: Decimal { get }
}

/// The narrow analytics surface `StakeModel` needs. `StakingSendAnalyticsLogger` refines it, so the
/// factory passes the real logger; tests need only a tiny mock.
protocol StakeModelAnalyticsLogger: StakingAnalyticsLogger {
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String)
    func logStakingTransactionRejected(error: SendTxError)
}

/// The single management model for the V2 staking flow.
///
/// Owns the shared Combine plumbing and the send pipeline; delegates all state computation, action
/// building, and the flow shape to a per-network `StakingFlowProvider`. There are no per-flow subclasses.
final class StakeModel {
    // MARK: - Data

    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _selectedTarget: CurrentValueSubject<LoadingResult<StakingTargetInfo, Never>, Never>
    private let _state = CurrentValueSubject<StakeFlowState, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: StakingModelRoutable?
    var amountExternalUpdater: SendAmountExternalUpdater?

    private let provider: StakingFlowProvider
    private let stepPlan: StakeStepPlan
    private let stakingManager: StakingManager
    private let sendSourceToken: SendStakingableToken
    private let accountInitializationService: BlockchainAccountInitializationService?
    private let analyticsLogger: StakeModelAnalyticsLogger

    private var estimatedFeeTask: Task<Void, Never>?
    private var timerTask: Task<Void, Error>?
    private var accountInitializationFee: Fee?
    private var bag: Set<AnyCancellable> = []

    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }

    init(
        provider: StakingFlowProvider,
        stakingManager: StakingManager,
        sendSourceToken: SendStakingableToken,
        accountInitializationService: BlockchainAccountInitializationService?,
        analyticsLogger: StakeModelAnalyticsLogger
    ) {
        self.provider = provider
        stepPlan = provider.stepPlan
        self.stakingManager = stakingManager
        self.sendSourceToken = sendSourceToken
        self.accountInitializationService = accountInitializationService
        self.analyticsLogger = analyticsLogger

        _amount = CurrentValueSubject(Self.initialAmount(stepPlan: provider.stepPlan, tokenItem: sendSourceToken.tokenItem))
        _selectedTarget = CurrentValueSubject(Self.initialTarget(provider: provider))

        bind()

        // Fixed flows have no input to wait for, so resolve immediately.
        if !stepPlan.amount.isEditable, !stepPlan.hasValidatorSelection {
            updateState()
        }
    }
}

// MARK: - Seeding

private extension StakeModel {
    static func initialAmount(stepPlan: StakeStepPlan, tokenItem: TokenItem) -> SendAmount? {
        let crypto: Decimal? = switch stepPlan.amount {
        case .editable(let preset): preset
        case .fixed(let value): value
        }

        guard let crypto else { return nil }

        let fiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(crypto, currencyId: $0) }
        return SendAmount(type: .typical(crypto: crypto, fiat: fiat))
    }

    /// A validator-selecting flow starts with no target (the user picks one); otherwise the target is
    /// baked into the action the provider was built with, so read it back through `makeAction`.
    static func initialTarget(provider: StakingFlowProvider) -> LoadingResult<StakingTargetInfo, Never> {
        guard !provider.stepPlan.hasValidatorSelection else { return .loading }
        let baked = provider.makeAction(amount: nil, target: nil).targetType.target
        return baked.map { .success($0) } ?? .loading
    }
}

// MARK: - State

private extension StakeModel {
    func bind() {
        if stepPlan.amount.isEditable {
            _amount
                .dropFirst()
                .withWeakCaptureOf(self)
                .sink { model, _ in model.updateState() }
                .store(in: &bag)
        }

        if stepPlan.hasValidatorSelection {
            _selectedTarget
                .compactMap { $0.value }
                .withWeakCaptureOf(self)
                .sink { model, _ in model.updateState() }
                .store(in: &bag)
        }
    }

    func updateState() {
        if stepPlan.amount.isEditable, _amount.value?.crypto == nil { return }
        if stepPlan.hasValidatorSelection, _selectedTarget.value.value == nil { return }

        guard sendSourceToken.canCoverStakingFee else {
            update(state: .failure(.network(StakingPreflightError.insufficientFundsForFee)))
            return
        }

        // After account initialization the init fee is already spent, so shrink a "max" amount by it to
        // keep the stake spendable (mirrors the legacy StakingModel).
        let enteredAmount = _amount.value?.crypto.map { $0 - (accountInitializationFee?.amount.value ?? .zero) }
        let target = _selectedTarget.value.value

        estimatedFeeTask?.cancel()
        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let state = try await model.provider.updateState(amount: enteredAmount, target: target)
                model.update(state: state)
            } catch is CancellationError {
                // Do nothing
            } catch {
                model.update(state: .failure(.network(error)))
            }
        }
    }

    func update(state: StakeFlowState) {
        if case .ready(let ready) = state {
            _isFeeIncluded.send(ready.isFeeIncluded)
        }
        _state.send(state)

        // The approval poll runs only while an approve tx is being mined. Keep it alive across transient
        // network errors so it retries (matching the legacy StakingModel); stop once the flow settles on
        // any other state, including a deterministic validation failure that re-polling can't clear.
        switch state {
        case .loading, .prerequisite(.approve(.inProgress)), .failure(.network):
            break
        default:
            stopTimer()
        }
    }

    func makeFee(_ value: Decimal) -> Fee {
        Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func mapToSendFee(_ state: StakeFlowState) -> TokenFee {
        switch state.feePresentation {
        case .loading:
            TokenFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .value(let fee):
            TokenFee(option: .market, tokenItem: feeTokenItem, value: .success(makeFee(fee)))
        case .failure(let error):
            TokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
        }
    }
}

// MARK: - Send

private extension StakeModel {
    func send() async throws -> TransactionDispatcherResult {
        guard case .ready(let ready) = _state.value else {
            throw StakeModelError.notReady
        }

        let action = provider.makeAction(amount: ready.amount, target: _selectedTarget.value.value)

        do {
            let transactionInfo = try await stakingManager.transaction(action: action)
            let dispatcher = sendSourceToken.transactionDispatcherProvider.makeStakingTransactionDispatcher(analyticsLogger: analyticsLogger)
            let result = try await dispatcher.send(transaction: .staking(transactionInfo))
            stakingManager.transactionDidSent(action: action)
            proceed(result: result)
            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch P2PStakingError.feeIncreased(let newFee) {
            update(state: provider.finalize(amount: ready.amount, fee: newFee, target: _selectedTarget.value.value))
            throw P2PStakingError.feeIncreased(newFee: newFee)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logStakingTransactionSent(
            amount: stepPlan.amount.isEditable ? _amount.value : .none,
            fee: .market,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )
    }

    func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .demoAlert, .userCancelled, .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased, .transactionNotFound,
             .feeNotFound, .loadTransactionInfo, .actionNotSupported:
            break
        case .sendTxError(_, let error):
            analyticsLogger.logStakingTransactionRejected(error: error)
        }
    }
}

// MARK: - Timer

private extension StakeModel {
    /// Re-resolves the flow every few seconds while an approval transaction is being mined, advancing it
    /// to `ready` once the allowance is confirmed. Started after an approve is sent; `update(state:)`
    /// stops it as soon as the flow leaves the approve-in-progress state. Mirrors the legacy StakingModel.
    func restartTimer() {
        timerTask?.cancel()
        timerTask = runTask(in: self) { model in
            try Task.checkCancellation()
            try await Task.sleep(for: .seconds(5))
            model.updateState()
            try Task.checkCancellation()
            model.restartTimer()
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

// MARK: - StakeModelStateProvider

extension StakeModel: StakeModelStateProvider {
    var state: StakeFlowState { _state.value }
    var statePublisher: AnyPublisher<StakeFlowState, Never> { _state.eraseToAnyPublisher() }

    var stakingAction: StakingAction {
        provider.makeAction(amount: _amount.value?.crypto, target: _selectedTarget.value.value)
    }

    /// The action the provider was built with carries the staked amount (the fixed/preset value).
    var stakedBalance: Decimal {
        provider.makeAction(amount: nil, target: nil).amount
    }

    /// Drives the summary bottom-button label: `.approve` only while an approval is actually required,
    /// otherwise the action's natural type (an in-progress approval keeps showing the action, matching
    /// the legacy flow). The V2 `StakeStepsManager` subscribes to this.
    var flowActionTypePublisher: AnyPublisher<SendFlowActionType, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, state in
                if case .prerequisite(.approve(.required)) = state {
                    return .approve
                }
                return model.provider.actionType.sendFlowActionType
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeUpdater

extension StakeModel: SendFeeUpdater {
    func updateFees() {
        updateState()
    }
}

// MARK: - SendSourceTokenInput

extension StakeModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> { .success(sendSourceToken) }
    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> { .just(output: sourceToken) }
}

// MARK: - SendSourceTokenOutput

extension StakeModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {}
}

// MARK: - SendSourceTokenAmountInput

extension StakeModel: SendSourceTokenAmountInput {
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

extension StakeModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        guard stepPlan.amount.isEditable else { return }
        _amount.send(amount)
    }
}

// MARK: - StakingTargetsInput

extension StakeModel: StakingTargetsInput {
    var selectedTarget: StakingTargetInfo? { _selectedTarget.value.value }
    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> {
        _selectedTarget.compactMap { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - StakingTargetsOutput

extension StakeModel: StakingTargetsOutput {
    func userDidSelect(target: StakingTargetInfo) {
        _selectedTarget.send(.success(target))
    }
}

// MARK: - SendFeeInput

extension StakeModel: SendFeeInput {
    var selectedFee: TokenFee? { mapToSendFee(_state.value) }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        _state.withWeakCaptureOf(self).map { $0.mapToSendFee($1) }.eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakeModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { $0.isReadyToSend }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        guard stepPlan.amount.isEditable, provider.actionType == .stake else {
            return .just(output: nil)
        }

        return Publishers.CombineLatest(_amount, stakingManager.statePublisher)
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

extension StakeModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> { _transactionURL.eraseToAnyPublisher() }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakeModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        Publishers.Merge(stakingManager.statePublisher.map(\.isLoading), _isLoading).eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }
        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakeModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension StakeModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateState()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .activate:
            openAccountInitializationFlow()
        case .reduceAmountBy(let amountToReduce, _, _):
            guard let oldAmount = sourceAmount.value?.main else { return }
            amountExternalUpdater?.externalUpdate(amount: oldAmount - amountToReduce)
            updateState()
        default:
            assertionFailure("StakeModel doesn't support notification action \(action)")
        }
    }

    private func openAccountInitializationFlow() {
        guard let accountInitializationService,
              case .prerequisite(.accountInitialization(.required(let initializationFee, _))) = _state.value else {
            return
        }

        let transactionDispatcher = sendSourceToken.transactionDispatcherProvider.makeTransferTransactionDispatcher()
        let tokenIconInfo = TokenIconInfoBuilder().build(from: sendSourceToken.tokenItem, isCustom: sendSourceToken.isCustom)

        let viewModel = BlockchainAccountInitializationViewModel(
            accountInitializationService: accountInitializationService,
            transactionDispatcher: transactionDispatcher,
            tangemIconProvider: sendSourceToken.tangemIconProvider,
            tokenItem: tokenItem,
            fee: initializationFee,
            feeTokenItem: feeTokenItem,
            tokenIconInfo: tokenIconInfo,
            onStartInitialization: { [weak self] in
                self?.update(state: .prerequisite(.accountInitialization(.inProgress)))
            },
            onInitialized: { [weak self] in
                self?.accountInitializationFee = initializationFee
                self?.updateState()
            }
        )

        router?.openAccountInitializationFlow(viewModel: viewModel)
    }
}

// MARK: - StakingBaseDataBuilderInput

extension StakeModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        _amount.value?.crypto.map { Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: $0) }
    }

    var bsdkFee: BSDKFee? { selectedFee?.value.value }
    var isFeeIncluded: Bool { _isFeeIncluded.value }
    var stakingActionType: StakingAction.ActionType? { provider.actionType }
    var target: StakingTargetInfo? { _selectedTarget.value.value }
}

// MARK: - ApproveFlowDataProvider, ApproveOutput

extension StakeModel: ApproveFlowDataProvider, ApproveOutput {
    func approveFlowInput() throws -> ApproveFlowInput {
        guard case .prerequisite(.approve(.required(let approveData, _))) = _state.value else {
            throw SendApproveViewModelInputDataBuilderError.notFound("Approve required state")
        }

        guard let approveAmount = _amount.value?.crypto else {
            throw SendApproveViewModelInputDataBuilderError.notFound("Approve amount")
        }

        return ApproveFlowInput(
            approveAmount: approveAmount,
            selectedPolicy: .specified,
            approveData: approveData,
            approvalFlow: .approve,
            sourceToken: sendSourceToken,
            tokenFeeProvidersManager: sendSourceToken.tokenFeeProvidersManager,
            localization: ApproveLocalization(
                title: Localization.swappingPermissionHeader,
                subtitle: Localization.givePermissionStakingSubtitle(tokenItem.currencySymbol),
                feeFooterText: Localization.stakingGivePermissionFeeFooter
            )
        )
    }

    func approveDidSendTransaction() {
        updateState()
        restartTimer()
    }
}
