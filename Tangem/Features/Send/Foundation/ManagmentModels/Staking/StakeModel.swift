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
    /// False on networks that delegate in place (Cardano), whose enter validates the fee only, like exits.
    var enterSpendsAmount: Bool { get }
}

/// The narrow analytics surface `StakeModel` needs. `StakingSendAnalyticsLogger` refines it, so the
/// factory passes the real logger; tests need only a tiny mock.
protocol StakeModelAnalyticsLogger: StakingAnalyticsLogger {
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String)
    func logStakingTransactionRejected(error: SendTxError)
    func logNoticeUninitializedAddress()
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

    // MARK: - Dependencies

    weak var router: StakingModelRoutable?
    var amountExternalUpdater: SendAmountExternalUpdater?

    private let provider: StakingFlowProvider
    private let sendSourceToken: SendStakingableToken
    private let accountInitializationService: BlockchainAccountInitializationService?
    private let validationHandler: StakingValidationHandler?
    private let analyticsLogger: StakeModelAnalyticsLogger
    private let autoupdatingTimer: AutoupdatingTimer

    private let estimatedFeeTask = OSAllocatedUnfairLock(initialState: Task<Void, Never>?.none)
    private var bag: Set<AnyCancellable> = []

    private var tokenItem: TokenItem { sendSourceToken.tokenItem }
    private var feeTokenItem: TokenItem { sendSourceToken.feeTokenItem }

    init(
        provider: StakingFlowProvider,
        sendSourceToken: SendStakingableToken,
        accountInitializationService: BlockchainAccountInitializationService?,
        validationHandler: StakingValidationHandler?,
        analyticsLogger: StakeModelAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        initialAmount: SendAmount?,
        initialTarget: LoadingResult<StakingTargetInfo, Never>,
        shouldUpdateStateInitially: Bool
    ) {
        self.provider = provider
        self.sendSourceToken = sendSourceToken
        self.accountInitializationService = accountInitializationService
        self.validationHandler = validationHandler
        self.analyticsLogger = analyticsLogger
        self.autoupdatingTimer = autoupdatingTimer

        _amount = CurrentValueSubject(initialAmount)
        _selectedTarget = CurrentValueSubject(initialTarget)

        bind()

        if shouldUpdateStateInitially {
            updateState()
        }
    }
}

// MARK: - State

private extension StakeModel {
    func bind() {
        _amount
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, _ in model.updateState(debounced: true) }
            .store(in: &bag)

        _selectedTarget
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .sink { model, _ in model.updateState() }
            .store(in: &bag)
    }

    func updateState(debounced: Bool = false) {
        // Cancelled ahead of the guard: an estimate left flying lands as a `.ready` built from the old amount.
        // Cancelled outside the lock too: `Task.cancel()` runs the task's cancellation handlers inline, and
        // one of them touching this state would deadlock on the held lock.
        let supersededEstimate = estimatedFeeTask.withLock { task -> Task<Void, Never>? in
            defer { task = nil }
            return task
        }

        supersededEstimate?.cancel()

        if let preflightError = sendSourceToken.stakingFeePreflightError {
            update(state: .failure(.network(preflightError)))
            return
        }

        let enteredAmount = _amount.value?.crypto
        let target = _selectedTarget.value.value

        update(state: .loading)

        let task = runTask(in: self) { model in
            do {
                if debounced {
                    // The amount arrives keystroke by keystroke, and a cancelled sleep never reaches the network.
                    try await Task.sleep(for: .seconds(1))
                }

                let state = try await model.provider.updateState(amount: enteredAmount, target: target)
                try Task.checkCancellation()
                model.update(state: state)
            } catch is CancellationError {
                // Do nothing
            } catch {
                // A cancelled network request surfaces as a plain error, not a `CancellationError`.
                guard !Task.isCancelled else {
                    return
                }

                model.update(state: .failure(.network(error)))
            }
        }

        estimatedFeeTask.withLock { $0 = task }
    }

    func update(state: StakeFlowState) {
        _state.send(state)
        updateAutoupdatingTimer(state: state)
        updateValidation(for: state)

        if case .prerequisite(.accountInitialization(.required)) = state {
            analyticsLogger.logNoticeUninitializedAddress()
        }
    }

    /// Polls only while an approval is mining: armed in the approve-in-progress state and re-armed by
    /// each resolve until the allowance confirms.
    func updateAutoupdatingTimer(state: StakeFlowState) {
        if case .prerequisite(.approve(.inProgress)) = state {
            autoupdatingTimer.setup { [weak self] in self?.updateState() }
        } else {
            autoupdatingTimer.setup(refresh: .none)
        }
    }

    /// Anti-blind-signing: the transaction behind the resolved action is built and screened ahead of the
    /// tap on Send, and the summary button stays disabled until the verdict allows sending. An approve
    /// prerequisite starts the screening early, so the verdict is usually in by the time the stake itself
    /// is ready.
    func updateValidation(for state: StakeFlowState) {
        switch state {
        case .ready(let ready):
            validationHandler?.validate(action: provider.makeAction(amount: ready.amount, target: _selectedTarget.value.value))
        case .prerequisite(.approve(.required)):
            guard let amount = _amount.value?.crypto else {
                validationHandler?.reset()
                return
            }
            validationHandler?.validate(action: provider.makeAction(amount: amount, target: _selectedTarget.value.value))
        case .loading, .prerequisite, .failure:
            validationHandler?.reset()
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
    /// Screens the transaction through the anti-blind-signing handler, or builds it directly when none is
    /// wired (network out of scope).
    func resolveTransaction(action: StakingAction) async throws -> StakingTransactionAction {
        guard let validationHandler else {
            return try await provider.buildTransaction(action: action)
        }
        return try await validationHandler.resolveTransaction(action: action, blockchain: tokenItem.blockchain)
    }

    func send() async throws -> TransactionDispatcherResult {
        await awaitSettled { estimatedFeeTask.withLock { $0 } }
        // The wait outlives cancellation of this send, so a superseded one stops before the dispatcher.
        try Task.checkCancellation()

        guard case .ready(let ready) = _state.value else {
            throw StakeModelError.notReady
        }

        let action = provider.makeAction(amount: ready.amount, target: _selectedTarget.value.value)

        do {
            let transactionInfo = try await resolveTransaction(action: action)

            // A real fee above the fee-included estimate re-states the flow and bounces the user back to
            // re-confirm (the framework error `SendViewModel` shows as the "fee is high" alert).
            if let restated = provider.reconcileBuiltFee(
                enteredAmount: _amount.value?.crypto,
                confirmed: ready,
                builtTransaction: transactionInfo,
                target: _selectedTarget.value.value
            ) {
                update(state: restated)
                throw TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased
            }

            let dispatcher = sendSourceToken.transactionDispatcherProvider.makeStakingTransactionDispatcher(analyticsLogger: analyticsLogger)
            let result = try await dispatcher.send(transaction: .staking(transactionInfo))
            provider.transactionDidSent(action: action)
            proceed(result: result)
            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch P2PStakingError.feeIncreased(let newFee) {
            update(state: provider.finalize(amount: _amount.value?.crypto ?? ready.amount, fee: newFee, target: _selectedTarget.value.value))
            throw P2PStakingError.feeIncreased(newFee: newFee)
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }
    }

    func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)
        analyticsLogger.logStakingTransactionSent(
            amount: provider.isAmountEditable ? _amount.value : .none,
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

// MARK: - StakeModelStateProvider

extension StakeModel: StakeModelStateProvider {
    var state: StakeFlowState { _state.value }
    var statePublisher: AnyPublisher<StakeFlowState, Never> { _state.eraseToAnyPublisher() }

    var stakingAction: StakingAction {
        provider.makeAction(amount: _amount.value?.crypto, target: _selectedTarget.value.value)
    }

    var stakedBalance: Decimal { provider.stakedBalance }

    var enterSpendsAmount: Bool { provider.enterSpendsAmount }

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
        guard provider.isAmountEditable else { return }
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
        Publishers.CombineLatest(_state, validationState)
            .map { state, validationState in state.isReadyToSend && validationState.allowsSending }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        guard provider.isAmountEditable, provider.actionType.isEnter else {
            return .just(output: nil)
        }

        return Publishers.CombineLatest(_amount, provider.statePublisher)
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
        Publishers.CombineLatest(provider.statePublisher.map(\.isLoading), _isLoading)
            .map { $0 || $1 }
            .eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }
        return try await send()
    }
}

// MARK: - StakingValidationStateProvider

extension StakeModel: StakingValidationStateProvider {
    /// Nil handler = staking validation isn't wired for this flow (feature off or network out of scope)
    /// → default to `.validated` so sending isn't blocked.
    var validationState: AnyPublisher<StakingValidationState, Never> {
        validationHandler?.validationState ?? Just(.validated).eraseToAnyPublisher()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakeModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        provider.statePublisher
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
                guard let self else { return }
                if let oldAmount = sourceAmount.value?.main {
                    amountExternalUpdater?.externalUpdate(amount: oldAmount - initializationFee.amount.value)
                }
                updateState()
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
    var isFeeIncluded: Bool {
        if case .ready(let ready) = _state.value { ready.isFeeIncluded } else { false }
    }

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
    }
}
