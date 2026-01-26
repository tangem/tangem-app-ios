//
//  ExpressInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress
import TangemMacro
import BlockchainSdk

class ExpressInteractor {
    // MARK: - Public

    public var state: AnyPublisher<State, Never> {
        _state.eraseToAnyPublisher()
    }

    public var swappingPair: AnyPublisher<SwappingPair, Never> {
        _swappingPair.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let userWalletInfo: UserWalletInfo
    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressAPIProvider: ExpressAPIProvider

    // MARK: - Options

    private let _state: CurrentValueSubject<State, Never> = .init(.idle)
    private let _swappingPair: CurrentValueSubject<SwappingPair, Never>

    private var updateStateTask: Task<Void, Error>?

    init(
        userWalletInfo: UserWalletInfo,
        swappingPair: SwappingPair,
        expressManager: ExpressManager,
        expressPairsRepository: ExpressPairsRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.userWalletInfo = userWalletInfo
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAPIProvider = expressAPIProvider

        _swappingPair = .init(swappingPair)
        initialLoading(source: swappingPair.sender, destination: swappingPair.destination)
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
    }
}

// MARK: - Getters

extension ExpressInteractor {
    func getState() -> State {
        _state.value
    }

    func getSwappingPair() -> SwappingPair {
        _swappingPair.value
    }

    func getSource() -> Source {
        _swappingPair.value.sender
    }

    func getSourceWallet() throws -> any ExpressInteractorSourceWallet {
        guard let sender = _swappingPair.value.sender.value else {
            throw ExpressInteractorError.sourceNotFound
        }

        return sender
    }

    func getDestination() -> (any ExpressInteractorDestinationWallet)? {
        _swappingPair.value.destination?.value
    }

    func getDestinationValue() -> Destination? {
        _swappingPair.value.destination
    }

    func providersPublisher() -> AnyPublisher<[ExpressAvailableProvider], Never> {
        state
            // Skip rates loading to avoid UI jumping
            .filter { !$0.isRefreshRates }
            .withWeakCaptureOf(self)
            .asyncMap { interactor, _ in
                await interactor.getAllProviders()
            }
            .eraseToAnyPublisher()
    }

    func selectedProviderPublisher() -> AnyPublisher<ExpressAvailableProvider?, Never> {
        state
            // Skip rates loading to avoid UI jumping
            .filter { !$0.isRefreshRates }
            .map { $0.context?.availableProvider }
            .eraseToAnyPublisher()
    }

    // Proxy methods

    func getAllProviders() async -> [ExpressAvailableProvider] {
        await expressManager.getAllProviders()
    }
}

// MARK: - Updates

extension ExpressInteractor {
    func swapPair() {
        guard
            let source = _swappingPair.value.sender.value,
            let destination = getDestination() as? ExpressInteractorSourceWallet else {
            log("The destination not found")
            return
        }

        let newPair = SwappingPair(sender: .success(destination), destination: .success(source))
        _swappingPair.value = newPair

        swappingPairDidChange()
    }

    func update(sender wallet: any ExpressInteractorSourceWallet) {
        log("Will update sender to \(wallet)")

        _swappingPair.value.sender = .success(wallet)
        swappingPairDidChange()
    }

    func update(destination wallet: (any ExpressInteractorDestinationWallet)?) {
        log("Will update destination to \(wallet as Any)")

        _swappingPair.value.destination = wallet.map { .success($0) }
        swappingPairDidChange()
    }

    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) {
        log("Will update amount to \(amount as Any)")

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(amount: amount, by: source)
            return try await interactor.mapState(state: state)
        }
    }

    func updateProvider(provider: ExpressAvailableProvider) {
        log("Will update provider to \(provider)")

        updateTask { interactor in
            let state = try await interactor.expressManager.updateSelectedProvider(provider: provider)
            return try await interactor.mapState(state: state)
        }
    }

    func updateApprovePolicy(policy: BSDKApprovePolicy) {
        updateState(.loading(type: .refreshRates))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(approvePolicy: policy)
            return try await interactor.mapState(state: state)
        }
    }

    func updateFeeOption(option: FeeOption) {
        updateState(.loading(type: .fee))
        updateTask { interactor in
            let feeOption: ExpressFee.Option = option == .fast ? .fast : .market
            let state = try await interactor.expressManager.update(feeOption: feeOption)
            return try await interactor.mapState(state: state)
        }
    }
}

// MARK: - ApproveViewModelInput

extension ExpressInteractor: ApproveViewModelInput {
    var approveFeeValue: LoadingResult<ApproveInputFee, any Error> {
        mapToApproveFeeLoadingValue(state: getState())
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingResult<ApproveInputFee, any Error>, Never> {
        state
            .withWeakCaptureOf(self)
            .compactMap { interactor, state in
                interactor.mapToApproveFeeLoadingValue(state: state)
            }
            .eraseToAnyPublisher()
    }

    private func mapToApproveFeeLoadingValue(state: ExpressInteractor.State) -> LoadingResult<ApproveInputFee, any Error> {
        switch state {
        case .permissionRequired(let state, _, _):
            return .success(state.fee)
        case .loading:
            return .loading
        case .requiredRefresh(let error, _):
            return .failure(error)
        default:
            // As default state
            return .loading
        }
    }
}

// MARK: - Send

extension ExpressInteractor {
    func send(shouldTrackAnalytics: Bool = true) async throws -> SentExpressTransactionData {
        guard let destination = getDestination() else {
            throw ExpressInteractorError.destinationNotFound
        }

        if shouldTrackAnalytics {
            logSwapTransactionAnalyticsEvent()
        }

        let result: TransactionSendResultState = try await {
            switch getState() {
            case .idle, .loading, .requiredRefresh, .restriction, .preloadRestriction:
                throw ExpressInteractorError.transactionDataNotFound
            case .permissionRequired:
                assertionFailure("Should called sendApproveTransaction()")
                throw ExpressInteractorError.transactionDataNotFound
            case .previewCEX(let state, let context, _):
                return try await sendCEXTransaction(state: state, context: context)
            case .readyToSwap(let state, let context, _):
                return try await sendDEXTransaction(state: state, context: context)
            }
        }()

        guard let tokenFeeProvidersManager = tokenFeeProvidersManager else {
            throw ExpressInteractorError.tokenFeeProvidersManagerNotFound
        }

        let source = try getSourceWallet()
        let expressSentResult = ExpressTransactionSentResult(
            hash: result.dispatcherResult.hash,
            source: source.tokenItem.expressCurrency,
            address: source.defaultAddressString,
            data: result.data
        )

        // Ignore error here
        try? await expressAPIProvider.exchangeSent(result: expressSentResult)

        updateState(.idle)
        let sentTransactionData = SentExpressTransactionData(
            result: result.dispatcherResult,
            source: source,
            destination: destination,
            fee: tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee,
            provider: result.provider,
            date: Date(),
            expressTransactionData: result.data
        )

        if shouldTrackAnalytics {
            logTransactionSentAnalyticsEvent(data: sentTransactionData, signerType: result.dispatcherResult.signerType)
        }

        expressPendingTransactionRepository.swapTransactionDidSend(
            sentTransactionData,
            userWalletId: userWalletInfo.id.stringValue
        )

        return sentTransactionData
    }

    func sendApproveTransaction() async throws {
        guard case .permissionRequired(let state, let context, let quote) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        await logApproveTransactionAnalyticsEvent(policy: state.policy)

        guard let allowanceService = try getSourceWallet().allowanceService else {
            throw ExpressInteractorError.allowanceServiceNotFound
        }

        let result = try await allowanceService.sendApproveTransaction(data: state.data)

        ExpressLogger.info("Sent the approve transaction with result: \(result)")
        logApproveTransactionSentAnalyticsEvent(policy: state.policy, signerType: result.signerType, currentProviderHost: result.currentHost)
        updateState(.restriction(.hasPendingApproveTransaction, context: context, quote: quote))
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: ExpressInteractor.RefreshType) {
        log("Was requested for refresh with \(type)")

        updateTask { interactor in
            interactor.log("Start refreshing task")
            interactor.updateState(.loading(type: type))

            // The type is full we can receive only from
            // the "Refresh" button on the error notification
            if type == .full {
                // If we have a restriction with destination after "refresh button"
                // Just show it
                if let restriction = try await interactor.updatePairsIfNeeded() {
                    return .preloadRestriction(restriction)
                }
            }

            let state = try await interactor.expressManager.update(by: .autoUpdate)
            return try await interactor.mapState(state: state)
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        log("Cancel the refreshing task")
        updateStateTask?.cancel()
        updateStateTask = nil
    }
}

// MARK: - State

private extension ExpressInteractor {
    func mapState(state provider: ExpressAvailableProvider?) async throws -> State {
        guard let provider else {
            return .idle
        }

        let source = try getSourceWallet()
        let state = await provider.getState()
        let tokenFeeProvidersManager = source.expressTokenFeeProvidersManager.tokenFeeProvidersManager(providerId: provider.provider.id)
        let context = Context(availableProvider: provider, tokenFeeProvidersManager: tokenFeeProvidersManager)

        switch state {
        case .idle:
            return .idle

        case .error(let error, .none):
            return .requiredRefresh(occurredError: error, quote: .none)

        case .error(let error, .some(let quote)):
            return try await .requiredRefresh(occurredError: error, quote: map(quote: quote))

        case .restriction(let restriction, .none):
            return try await .restriction(map(restriction: restriction), context: context, quote: .none)

        case .restriction(let restriction, .some(let quote)):
            return try await .restriction(map(restriction: restriction), context: context, quote: map(quote: quote))

        case .permissionRequired(let permissionRequired) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, context: context, quote: map(quote: permissionRequired.quote))

        case .preview(let previewCEX) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, context: context, quote: map(quote: previewCEX.quote))

        case .ready(let ready) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, context: context, quote: map(quote: ready.quote))

        case .permissionRequired(let permissionRequired):
            return try await map(permissionRequired: permissionRequired, in: context)

        case .preview(let previewCEX):
            return try await map(previewCEX: previewCEX, in: context)

        case .ready(let ready):
            return try await map(ready: ready, in: context)
        }
    }

    func updateState(_ state: State) {
        log("Update state to \(state)")

        if let sender = getSource().value, case .restriction(.notEnoughAmountForFee, _, _) = state {
            Analytics.log(
                event: .swapNoticeNotEnoughFee,
                params: [
                    .token: sender.tokenItem.currencySymbol,
                    .blockchain: sender.tokenItem.blockchain.displayName,
                ]
            )
        }

        _state.send(state)
    }
}

// MARK: - Mapping

private extension ExpressInteractor {
    func hasPendingTransaction() -> Bool {
        let hasPendingTransaction = getSource().value?.sendingRestrictions?.isHasPendingTransaction
        return hasPendingTransaction ?? false
    }

    func map(restriction: ExpressRestriction) async throws -> RestrictionType {
        switch restriction {
        case .tooSmallAmount(let minAmount):
            return .tooSmallAmountForSwapping(minAmount: minAmount)

        case .tooBigAmount(let maxAmount):
            return .tooBigAmountForSwapping(maxAmount: maxAmount)

        case .approveTransactionInProgress:
            return .hasPendingApproveTransaction

        case .insufficientBalance(let requiredAmount):
            return .notEnoughBalanceForSwapping(requiredAmount: requiredAmount)

        case .feeCurrencyHasZeroBalance(let isFeeCurrency):
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)

        case .feeCurrencyInsufficientBalanceForTxValue(let fee, let isFeeCurrency):
            return .notEnoughAmountForTxValue(fee, isFeeCurrency: isFeeCurrency)
        }
    }

    func map(permissionRequired: ExpressProviderManagerState.PermissionRequired, in context: Context) async throws -> State {
        let sender = try getSourceWallet()
        let amount = makeAmount(value: permissionRequired.quote.fromAmount, tokenItem: sender.tokenItem)
        let fee = permissionRequired.data.fee
        let approveFee = ApproveInputFee(feeTokenItem: sender.feeTokenItem, fee: fee)

        let permissionRequiredState = PermissionRequiredState(
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            fee: approveFee
        )

        let quote = try await map(quote: permissionRequired.quote)
        let correctState: State = .permissionRequired(permissionRequiredState, context: context, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState, in: context)
    }

    func map(ready: ExpressProviderManagerState.Ready, in context: Context) async throws -> State {
        let sender = try getSourceWallet()
        let selectedTokenFee = context.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee
        let fee = try selectedTokenFee.value.get()

        let amount = makeAmount(value: ready.quote.fromAmount, tokenItem: sender.tokenItem)
        let quote = try await map(quote: ready.quote)

        let readyToSwapState = ReadyToSwapState(data: ready.data)
        let correctState: State = .readyToSwap(readyToSwapState, context: context, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState, in: context)
    }

    func map(previewCEX: ExpressProviderManagerState.PreviewCEX, in context: Context) async throws -> State {
        let sender = try getSourceWallet()
        let selectedTokenFee = context.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee
        let fee = try selectedTokenFee.value.get()

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: sender.tokenItem)
        let quote = try await map(quote: previewCEX.quote)

        let withdrawalNotificationProvider = sender.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = getDestination() as? ExpressInteractorSourceWallet,
           previewCEX.quote.expectAmount < destination.amountToCreateAccount {
            let restriction = RestrictionType.notEnoughReceivedAmount(
                minAmount: destination.amountToCreateAccount,
                tokenSymbol: destination.tokenItem.currencySymbol
            )

            return .restriction(restriction, context: context, quote: quote,)
        }

        let subtractFee = SubtractFee(feeTokenItem: selectedTokenFee.tokenItem, subtractFee: previewCEX.subtractFee)

        let previewCEXState = PreviewCEXState(
            subtractFee: subtractFee,
            isExemptFee: sender.isExemptFee,
            notification: notification
        )

        let correctState: State = .previewCEX(previewCEXState, context: context, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState, in: context)
    }

    func validate(amount: Amount, fee: Fee, correctState: State, in context: Context) -> State {
        do {
            let transactionValidator = try getSourceWallet().transactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: amount.value), context: context, quote: correctState.quote)
        } catch ValidationError.feeExceedsBalance {
            let isFeeCurrency = fee.amount.type == amount.type
            return .restriction(.notEnoughAmountForFee(isFeeCurrency: isFeeCurrency), context: context, quote: correctState.quote)
        } catch let error as ValidationError {
            let isFeeCurrency = fee.amount.type == amount.type
            let validationErrorContext = ValidationErrorContext(isFeeCurrency: isFeeCurrency, feeValue: fee.amount.value)
            return .restriction(.validationError(error: error, context: validationErrorContext), context: context, quote: correctState.quote)
        } catch {
            return .requiredRefresh(occurredError: error, quote: correctState.quote)
        }

        return correctState
    }

    func map(quote: ExpressQuote) async throws -> Quote {
        let highPriceImpact = try await calculateHighPriceImpact(quote: quote)
        return Quote(
            fromAmount: quote.fromAmount,
            expectAmount: quote.expectAmount,
            highPriceImpact: highPriceImpact
        )
    }

    func calculateHighPriceImpact(quote: ExpressQuote?) async throws -> HighPriceImpactCalculator.Result? {
        guard let provider = getState().context?.availableProvider.provider,
              let quote,
              let sourceCurrency = _swappingPair.value.sender.value?.tokenItem,
              let destinationCurrency = _swappingPair.value.destination?.value?.tokenItem else {
            return nil
        }

        let priceImpactCalculator = HighPriceImpactCalculator(source: sourceCurrency, destination: destinationCurrency)
        let result = try await priceImpactCalculator.isHighPriceImpact(provider: provider, quote: quote)
        return result
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func sendDEXTransaction(state: ReadyToSwapState, context: Context) async throws -> TransactionSendResultState {
        let sender = try getSourceWallet()
        let fee = try context.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.value.get()
        let processor = try sender.dexTransactionProcessor()
        let result = try await processor.process(data: state.data, fee: fee)

        return TransactionSendResultState(dispatcherResult: result, data: state.data, fee: fee, provider: context.provider)
    }

    func sendCEXTransaction(state: PreviewCEXState, context: Context) async throws -> TransactionSendResultState {
        let sender = try getSourceWallet()
        let fee = try context.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.value.get()
        let data = try await expressManager.requestData()
        let processor = try sender.cexTransactionProcessor()
        let result = try await processor.process(data: data, fee: fee)

        return TransactionSendResultState(dispatcherResult: result, data: data, fee: fee, provider: context.provider)
    }
}

// MARK: - Changes

private extension ExpressInteractor {
    func swappingPairDidChange() {
        updateTask { interactor in
            guard let destination = interactor.getDestination() else {
                let state = try await interactor.expressManager.update(pair: .none)
                return try await interactor.mapState(state: state)
            }

            // If we have an amount to we will start the full update
            if let amount = await interactor.expressManager.getAmount(), amount > 0 {
                interactor.updateState(.loading(type: .full))
            }

            let sender = try interactor.getSourceWallet()
            let pair = ExpressManagerSwappingPair(source: sender, destination: destination)
            let state = try await interactor.expressManager.update(pair: pair)
            return try await interactor.mapState(state: state)
        }
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension ExpressInteractor: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        getState().context?.tokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        state
            .compactMap { $0.context?.tokenFeeProvidersManager }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension ExpressInteractor: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        getSource().value?.expressTokenFeeProvidersManager
            .updateSelectedFeeTokenItemInAllManagers(feeTokenItem: feeTokenItem)

        getSource().value?.expressTokenFeeProvidersManager
            .updateSelectedFeeOptionInAllManagers(feeOption: feeOption)

        refresh(type: .fee)
    }
}

// MARK: - Helpers

private extension ExpressInteractor {
    func updateTask(block: @escaping (_ interactor: ExpressInteractor) async throws -> State) {
        cancelRefresh()
        updateStateTask = Task { [weak self] in
            guard let self else { return }

            do {
                let state = try await block(self)
                try Task.checkCancellation()
                updateState(state)
            } catch is CancellationError {
                // Do nothing
                log("The update task was cancelled")
            } catch {
                switch error {
                case let error as ExpressAPIError:
                    await logExpressError(error)
                case let error as ExpressProviderError where error == .transactionSizeNotSupported:
                    await logExpressError(error)
                default:
                    break
                }

                let quote = getState().quote
                updateState(.requiredRefresh(occurredError: error, quote: quote))
            }
        }
    }

    func initialLoading(source: Source, destination: Destination?) {
        updateTask { interactor in
            if let restriction = try await interactor.initialLoading(source: source, destination: destination) {
                return .preloadRestriction(restriction)
            }

            return .idle
        }
    }

    func updatePairsIfNeeded() async throws -> PreloadRestrictionType? {
        guard getSource().value == nil || getDestination() == nil else {
            return nil
        }

        return try await initialLoading(source: _swappingPair.value.sender, destination: _swappingPair.value.destination)
    }

    func initialLoading(source: Source, destination: Destination?) async throws -> PreloadRestrictionType? {
        do {
            switch (source, destination) {
            case (.success, .none):
                log("Destination loading is not needed")

            case (.success, .success):
                // All already set
                swappingPairDidChange()

            case (.success(let source), _):
                try await expressPairsRepository.updatePairs(for: source.tokenItem.expressCurrency, userWalletInfo: userWalletInfo)

                _swappingPair.value.destination = .loading
                let destination = try await expressDestinationService.getDestination(source: source)
                update(destination: destination)

            case (_, .success(let destination)):
                try await expressPairsRepository.updatePairs(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: userWalletInfo
                )
                _swappingPair.value.sender = .loading
                let source = try await expressDestinationService.getSource(destination: destination)
                update(sender: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _swappingPair.value.sender = .failure(ExpressInteractorError.sourceNotFound)
                _swappingPair.value.destination = .failure(ExpressInteractorError.destinationNotFound)
            }

            return nil
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            log("Destination not found")
            _swappingPair.value.sender = .failure(ExpressDestinationServiceError.sourceNotFound(destination: destination))
            return .noSourceTokens(destination: destination.tokenItem)
        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            log("Destination not found")
            _swappingPair.value.destination = .failure(ExpressDestinationServiceError.destinationNotFound(source: source))
            return .noDestinationTokens(source: source.tokenItem)
        } catch {
            log("Get destination failed with error: \(error)")
            if _swappingPair.value.destination?.isLoading == true {
                _swappingPair.value.destination = .failure(error)
            }

            if _swappingPair.value.sender.isLoading {
                _swappingPair.value.sender = .failure(error)
            }

            throw error
        }
    }

    func makeAmount(value: Decimal, tokenItem: TokenItem) -> Amount {
        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func getTokenFeeProvidersManager(providerId: ExpressProvider.Id) throws -> TokenFeeProvidersManager {
        let source = try getSourceWallet()
        let tokenFeeProvidersManager = source.expressTokenFeeProvidersManager.tokenFeeProvidersManager(providerId: providerId)
        return tokenFeeProvidersManager
    }
}

// MARK: - Log

private extension ExpressInteractor {
    func log(_ args: Any) {
        ExpressLogger.info(self, args)
    }
}

// MARK: - Analytics

private extension ExpressInteractor {
    func logSwapTransactionAnalyticsEvent() {
        guard let source = getSource().value,
              let destination = getDestination() else {
            return
        }

        source.interactorAnalyticsLogger
            .logSwapTransactionAnalyticsEvent(destination: destination.tokenItem)
    }

    func logApproveTransactionAnalyticsEvent(policy: BSDKApprovePolicy) async {
        guard let source = getSource().value,
              let destination = getDestination(),
              let provider = getState().context?.provider else {
            return
        }

        source.interactorAnalyticsLogger.logApproveTransactionAnalyticsEvent(
            policy: policy,
            provider: provider,
            destination: destination.tokenItem
        )
    }

    func logApproveTransactionSentAnalyticsEvent(
        policy: BSDKApprovePolicy,
        signerType: String,
        currentProviderHost: String
    ) {
        getSource().value?.interactorAnalyticsLogger
            .logApproveTransactionSentAnalyticsEvent(
                policy: policy,
                signerType: signerType,
                currentProviderHost: currentProviderHost
            )
    }

    func logExpressError(_ error: Error) async {
        let selectedProvider = getState().context?.provider
        getSource().value?.interactorAnalyticsLogger.logExpressError(error, provider: selectedProvider)
    }

    func logTransactionSentAnalyticsEvent(data: SentExpressTransactionData, signerType: String) {
        let analyticsFeeType: Analytics.ParameterValue = {
            if tokenFeeProvidersManager?.selectedFeeProvider.hasMultipleFeeOptions == false {
                return .transactionFeeFixed
            }

            return data.fee.option.analyticsValue
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: data.source.tokenItem),
            .blockchain: data.source.tokenItem.blockchain.displayName,
            .feeType: analyticsFeeType.rawValue,
            .walletForm: signerType,
            .selectedHost: data.result.currentHost,
        ], analyticsSystems: .all)
    }
}

// MARK: - CustomStringConvertible

extension ExpressInteractor: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Models

enum ExpressInteractorError: String, LocalizedError {
    case feeNotFound
    case quoteNotFound
    case allowanceServiceNotFound
    case transactionDataNotFound
    case sourceNotFound
    case destinationNotFound
    case providerNotFound
    case amountNotFound
    case tokenFeeProvidersManagerNotFound

    var errorDescription: String? {
        return rawValue
    }
}

// MARK: - State

extension ExpressInteractor {
    enum State {
        case idle
        case requiredRefresh(occurredError: Error, quote: Quote?)
        case preloadRestriction(PreloadRestrictionType)
        case loading(type: RefreshType)
        case restriction(RestrictionType, context: Context, quote: Quote?)
        case permissionRequired(PermissionRequiredState, context: Context, quote: Quote)
        case previewCEX(PreviewCEXState, context: Context, quote: Quote)
        case readyToSwap(ReadyToSwapState, context: Context, quote: Quote)

        var quote: Quote? {
            switch self {
            case .idle, .loading, .requiredRefresh, .preloadRestriction:
                return nil
            case .restriction(_, _, let quote):
                return quote
            case .readyToSwap(_, _, let quote), .previewCEX(_, _, let quote), .permissionRequired(_, _, let quote):
                return quote
            }
        }

        var context: Context? {
            switch self {
            case .idle, .loading, .requiredRefresh, .preloadRestriction:
                return nil
            case .restriction(_, let context, _),
                 .permissionRequired(_, let context, _),
                 .readyToSwap(_, let context, _),
                 .previewCEX(_, let context, _):
                return context
            }
        }

        var isAvailableToSendTransaction: Bool {
            switch self {
            case .readyToSwap, .previewCEX:
                return true
            case .idle, .loading, .restriction, .preloadRestriction, .requiredRefresh, .permissionRequired:
                return false
            }
        }

        var isFeeRowVisible: Bool {
            switch self {
            case .idle,
                 .loading,
                 .preloadRestriction,
                 .requiredRefresh,
                 .permissionRequired,
                 .restriction(.hasPendingApproveTransaction, _, _):
                return false
            case .restriction, .readyToSwap, .previewCEX:
                return true
            }
        }

        var isRefreshRates: Bool {
            switch self {
            case .loading(.refreshRates): true
            default: false
            }
        }
    }

    // MARK: - State models

    enum RefreshType {
        case full
        case refreshRates
        case fee
    }

    enum PreloadRestrictionType {
        case noSourceTokens(destination: TokenItem)
        case noDestinationTokens(source: TokenItem)
    }

    enum RestrictionType {
        case tooSmallAmountForSwapping(minAmount: Decimal)
        case tooBigAmountForSwapping(maxAmount: Decimal)
        case hasPendingTransaction
        case hasPendingApproveTransaction
        case notEnoughBalanceForSwapping(requiredAmount: Decimal)
        case notEnoughAmountForFee(isFeeCurrency: Bool)
        case notEnoughAmountForTxValue(_ estimatedTxValue: Decimal, isFeeCurrency: Bool)
        case validationError(error: ValidationError, context: ValidationErrorContext)
        case notEnoughReceivedAmount(minAmount: Decimal, tokenSymbol: String)
    }

    struct Context {
        let availableProvider: ExpressAvailableProvider
        let tokenFeeProvidersManager: TokenFeeProvidersManager

        var provider: ExpressProvider { availableProvider.provider }
    }

    struct Quote: Hashable {
        let fromAmount: Decimal
        let expectAmount: Decimal
        let highPriceImpact: HighPriceImpactCalculator.Result?
    }

    struct PermissionRequiredState {
        let policy: BSDKApprovePolicy
        let data: ApproveTransactionData
        let fee: ApproveInputFee
    }

    struct PreviewCEXState {
        let subtractFee: SubtractFee
        let isExemptFee: Bool
        let notification: WithdrawalNotification?
    }

    struct SubtractFee {
        let feeTokenItem: TokenItem
        let subtractFee: Decimal
    }

    struct ReadyToSwapState {
        let data: ExpressTransactionData
    }

    // Manager models

    typealias Source = LoadingResult<any ExpressInteractorSourceWallet, Error>
    typealias Destination = LoadingResult<any ExpressInteractorDestinationWallet, Error>

    struct SwappingPair {
        var sender: Source
        var destination: Destination?
    }

    struct TransactionSendResultState {
        let dispatcherResult: TransactionDispatcherResult
        let data: ExpressTransactionData
        let fee: Fee
        let provider: ExpressProvider
    }
}
