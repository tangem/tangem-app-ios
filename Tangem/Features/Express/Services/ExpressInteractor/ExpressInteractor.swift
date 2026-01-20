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
            .withWeakCaptureOf(self)
            .asyncMap { interactor, _ in
                await interactor.getSelectedProvider()
            }
            .eraseToAnyPublisher()
    }

    // Proxy methods

    func getAllProviders() async -> [ExpressAvailableProvider] {
        await expressManager.getAllProviders()
    }

    func getSelectedProvider() async -> ExpressAvailableProvider? {
        await expressManager.getSelectedProvider()
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

        updateState(.loading(type: .full, previous: getState()))
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
        updateState(.loading(type: .refreshRates, previous: getState()))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(approvePolicy: policy)
            return try await interactor.mapState(state: state)
        }
    }

    func updateFeeOption(option: FeeOption) {
        updateState(.loading(type: .fee, previous: getState()))
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
        case .permissionRequired(let state, _):
            return .success(state.fee)
        case .loading:
            return .loading
        case .restriction(.requiredRefresh(let error), _):
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
            case .idle, .loading, .restriction:
                throw ExpressInteractorError.transactionDataNotFound
            case .permissionRequired:
                assertionFailure("Should called sendApproveTransaction()")
                throw ExpressInteractorError.transactionDataNotFound
            case .previewCEX(let state, _):
                guard let provider = await expressManager.getSelectedProvider() else {
                    throw ExpressInteractorError.providerNotFound
                }
                return try await sendCEXTransaction(state: state, provider: provider.provider)
            case .readyToSwap(let state, _):
                guard let provider = await expressManager.getSelectedProvider() else {
                    throw ExpressInteractorError.providerNotFound
                }

                return try await sendDEXTransaction(state: state, provider: provider.provider)
            }
        }()

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
            fee: result.fee.amount.value,
            feeOption: tokenFeeProvidersManager?.selectedFeeProvider.selectedTokenFee.option ?? .market,
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
        guard case .permissionRequired(let state, _) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        await logApproveTransactionAnalyticsEvent(policy: state.policy)

        guard let allowanceService = try getSourceWallet().allowanceService else {
            throw ExpressInteractorError.allowanceServiceNotFound
        }

        let result = try await allowanceService.sendApproveTransaction(data: state.data)

        ExpressLogger.info("Sent the approve transaction with result: \(result)")
        logApproveTransactionSentAnalyticsEvent(policy: state.policy, signerType: result.signerType, currentProviderHost: result.currentHost)
        updateState(.restriction(.hasPendingApproveTransaction, quote: getState().quote))
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: ExpressInteractor.RefreshType) {
        log("Was requested for refresh with \(type)")

        updateTask { interactor in
            interactor.log("Start refreshing task")
            interactor.updateState(.loading(type: type, previous: interactor.getState()))

            // The type is full we can receive only from
            // the "Refresh" button on the error notification
            if type == .full {
                // If we have a restriction with destination after "refresh button"
                // Just show it
                if let restriction = await interactor.updatePairsIfNeeded() {
                    return .restriction(restriction, quote: .none)
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
    func mapState(state: ExpressManagerState) async throws -> State {
        switch state {
        case .idle:
            return .idle

        case .restriction(let restriction, let quote):
            return try await map(restriction: restriction, quote: quote)

        case .permissionRequired(let permissionRequired) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, quote: map(quote: permissionRequired.quote))

        case .previewCEX(let previewCEX) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, quote: map(quote: previewCEX.quote))

        case .ready(let ready) where hasPendingTransaction():
            return try await .restriction(.hasPendingTransaction, quote: map(quote: ready.quote))

        case .permissionRequired(let permissionRequired):
            return try await map(permissionRequired: permissionRequired)

        case .previewCEX(let previewCEX):
            return try await map(previewCEX: previewCEX)

        case .ready(let ready):
            return try await map(ready: ready)
        }
    }

    func updateState(_ state: State) {
        log("Update state to \(state)")

        if let sender = getSource().value, case .restriction(.notEnoughAmountForFee, _) = state {
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

    func map(restriction: ExpressRestriction, quote: ExpressQuote?) async throws -> State {
        let quote: Quote? = try await {
            if let quote {
                return try await map(quote: quote)
            }

            return nil
        }()

        switch restriction {
        case .tooSmallAmount(let minAmount):
            return .restriction(.tooSmallAmountForSwapping(minAmount: minAmount), quote: quote)

        case .tooBigAmount(let maxAmount):
            return .restriction(.tooBigAmountForSwapping(maxAmount: maxAmount), quote: quote)

        case .approveTransactionInProgress:
            return .restriction(.hasPendingApproveTransaction, quote: quote)

        case .insufficientBalance(let requiredAmount):
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: requiredAmount), quote: quote)

        case .feeCurrencyHasZeroBalance(let isFeeCurrency):
            return .restriction(.notEnoughAmountForFee(isFeeCurrency: isFeeCurrency), quote: quote)

        case .feeCurrencyInsufficientBalanceForTxValue(let fee, let isFeeCurrency):
            return .restriction(.notEnoughAmountForTxValue(fee, isFeeCurrency: isFeeCurrency), quote: quote)
        }
    }

    func map(permissionRequired: ExpressManagerState.PermissionRequired) async throws -> State {
        let sender = try getSourceWallet()
        let amount = makeAmount(value: permissionRequired.quote.fromAmount, tokenItem: sender.tokenItem)
        let fee = permissionRequired.data.fee
        let quote = try await map(quote: permissionRequired.quote)

        let tokenFeeProvidersManager = try getTokenFeeProvidersManager(providerId: permissionRequired.provider.id)
        let feeTokenItem = tokenFeeProvidersManager.selectedFeeProvider.feeTokenItem
        let approveFee = ApproveInputFee(feeTokenItem: feeTokenItem, fee: fee)

        let permissionRequiredState = PermissionRequiredState(
            provider: permissionRequired.provider,
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            fee: approveFee
        )
        let correctState: State = .permissionRequired(permissionRequiredState, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(ready: ExpressManagerState.Ready) async throws -> State {
        let sender = try getSourceWallet()
        let tokenFeeProvidersManager = try getTokenFeeProvidersManager(providerId: ready.provider.id)
        let selectedTokenFee = tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee
        let fee = try selectedTokenFee.value.get()

        let amount = makeAmount(value: ready.quote.fromAmount, tokenItem: sender.tokenItem)
        let quote = try await map(quote: ready.quote)

        let readyToSwapState = ReadyToSwapState(provider: ready.provider, tokenFeeProvidersManager: tokenFeeProvidersManager, data: ready.data)
        let correctState: State = .readyToSwap(readyToSwapState, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(previewCEX: ExpressManagerState.PreviewCEX) async throws -> State {
        let sender = try getSourceWallet()
        let tokenFeeProvidersManager = try getTokenFeeProvidersManager(providerId: previewCEX.provider.id)
        let selectedTokenFee = tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee
        let fee = try selectedTokenFee.value.get()

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: sender.tokenItem)
        let quote = try await map(quote: previewCEX.quote)

        let withdrawalNotificationProvider = sender.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = getDestination() as? ExpressInteractorSourceWallet,
           previewCEX.quote.expectAmount < destination.amountToCreateAccount {
            return .restriction(
                .notEnoughReceivedAmount(minAmount: destination.amountToCreateAccount, tokenSymbol: destination.tokenItem.currencySymbol),
                quote: quote
            )
        }

        let subtractFee = SubtractFee(feeTokenItem: selectedTokenFee.tokenItem, subtractFee: previewCEX.subtractFee)

        let previewCEXState = PreviewCEXState(
            provider: previewCEX.provider,
            tokenFeeProvidersManager: tokenFeeProvidersManager,
            subtractFee: subtractFee,
            isExemptFee: sender.isExemptFee,
            notification: notification
        )
        let correctState: State = .previewCEX(previewCEXState, quote: quote)

        return validate(amount: amount, fee: fee, correctState: correctState)
    }

    func validate(amount: Amount, fee: Fee, correctState: State) -> State {
        do {
            let transactionValidator = try getSourceWallet().transactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: amount.value), quote: correctState.quote)
        } catch ValidationError.feeExceedsBalance {
            let isFeeCurrency = fee.amount.type == amount.type
            return .restriction(.notEnoughAmountForFee(isFeeCurrency: isFeeCurrency), quote: correctState.quote)
        } catch let error as ValidationError {
            let isFeeCurrency = fee.amount.type == amount.type
            let context = ValidationErrorContext(isFeeCurrency: isFeeCurrency, feeValue: fee.amount.value)
            return .restriction(.validationError(error: error, context: context), quote: correctState.quote)
        } catch {
            return .restriction(.requiredRefresh(occurredError: error), quote: correctState.quote)
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
        guard let provider = await getSelectedProvider()?.provider,
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
    func sendDEXTransaction(state: ReadyToSwapState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let sender = try getSourceWallet()
        let fee = try state.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.value.get()
        let processor = try sender.dexTransactionProcessor()
        let result = try await processor.process(data: state.data, fee: fee)

        return TransactionSendResultState(dispatcherResult: result, data: state.data, fee: fee, provider: provider)
    }

    func sendCEXTransaction(state: PreviewCEXState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let sender = try getSourceWallet()
        let fee = try state.tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.value.get()
        let data = try await expressManager.requestData()
        let processor = try sender.cexTransactionProcessor()
        let result = try await processor.process(data: data, fee: fee)

        return TransactionSendResultState(dispatcherResult: result, data: data, fee: fee, provider: provider)
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
                interactor.updateState(.loading(type: .full, previous: interactor.getState()))
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
        switch getState() {
        case .loading(_, previous: .previewCEX(let state, _)):
            return state.tokenFeeProvidersManager
        case .loading(_, previous: .readyToSwap(let state, _)):
            return state.tokenFeeProvidersManager
        case .previewCEX(let state, _):
            return state.tokenFeeProvidersManager
        case .readyToSwap(let state, _):
            return state.tokenFeeProvidersManager
        case .idle, .loading, .permissionRequired, .restriction:
            return nil
        }
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        state.compactMap { state in
            switch state {
            case .loading(_, previous: .previewCEX(let state, _)):
                return state.tokenFeeProvidersManager
            case .loading(_, previous: .readyToSwap(let state, _)):
                return state.tokenFeeProvidersManager
            case .previewCEX(let state, _):
                return state.tokenFeeProvidersManager
            case .readyToSwap(let state, _):
                return state.tokenFeeProvidersManager
            case .idle, .loading, .permissionRequired, .restriction:
                return nil
            }
        }
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
            } catch {
                if error is CancellationError || Task.isCancelled {
                    // Do nothing
                    log("The update task was cancelled")
                    return
                }

                switch error {
                case let error as ExpressAPIError:
                    await logExpressError(error)
                case let error as ExpressProviderError where error == .transactionSizeNotSupported:
                    await logExpressError(error)
                default:
                    break
                }

                let quote = getState().quote
                updateState(.restriction(.requiredRefresh(occurredError: error), quote: quote))
            }
        }
    }

    func initialLoading(source: Source, destination: Destination?) {
        updateTask { interactor in
            if let restriction = await interactor.initialLoading(source: source, destination: destination) {
                return .restriction(restriction, quote: .none)
            }

            return .idle
        }
    }

    func updatePairsIfNeeded() async -> RestrictionType? {
        guard getSource().value == nil || getDestination() == nil else {
            return nil
        }

        return await initialLoading(source: _swappingPair.value.sender, destination: _swappingPair.value.destination)
    }

    func initialLoading(source: Source, destination: Destination?) async -> RestrictionType? {
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
                return nil
            }
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

            return .requiredRefresh(occurredError: error)
        }

        return nil
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
              let provider = await getSelectedProvider() else {
            return
        }

        source.interactorAnalyticsLogger
            .logApproveTransactionAnalyticsEvent(
                policy: policy,
                provider: provider.provider,
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
        let selectedProvider = await getSelectedProvider()
        getSource().value?.interactorAnalyticsLogger
            .logExpressError(error, provider: selectedProvider?.provider)
    }

    func logTransactionSentAnalyticsEvent(data: SentExpressTransactionData, signerType: String) {
        let analyticsFeeType: Analytics.ParameterValue = {
            if tokenFeeProvidersManager?.selectedFeeProvider.hasMultipleFeeOptions == false {
                return .transactionFeeFixed
            }

            return data.feeOption.analyticsValue
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: data.source.tokenItem),
            .blockchain: data.source.tokenItem.blockchain.displayName,
            .feeType: analyticsFeeType.rawValue,
            .walletForm: signerType,
            .selectedHost: data.result.currentHost,
        ])
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

    var errorDescription: String? {
        return rawValue
    }
}

// MARK: - State

extension ExpressInteractor {
    indirect enum State {
        case idle
        case loading(type: RefreshType, previous: State)
        case restriction(RestrictionType, quote: Quote?)
        case permissionRequired(PermissionRequiredState, quote: Quote)
        case previewCEX(PreviewCEXState, quote: Quote)
        case readyToSwap(ReadyToSwapState, quote: Quote)

        var quote: Quote? {
            switch self {
            case .idle, .loading:
                return nil
            case .restriction(_, let quote):
                return quote
            case .readyToSwap(_, let quote), .previewCEX(_, let quote), .permissionRequired(_, let quote):
                return quote
            }
        }

        var isAvailableToSendTransaction: Bool {
            switch self {
            case .readyToSwap, .permissionRequired, .previewCEX:
                return true
            case .idle, .loading, .restriction:
                return false
            }
        }

        var isRefreshRates: Bool {
            switch self {
            case .loading(.refreshRates, _): true
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

    enum RestrictionType {
        case tooSmallAmountForSwapping(minAmount: Decimal)
        case tooBigAmountForSwapping(maxAmount: Decimal)
        case hasPendingTransaction
        case hasPendingApproveTransaction
        case notEnoughBalanceForSwapping(requiredAmount: Decimal)
        case notEnoughAmountForFee(isFeeCurrency: Bool)
        case notEnoughAmountForTxValue(_ estimatedTxValue: Decimal, isFeeCurrency: Bool)
        case requiredRefresh(occurredError: Error)
        case noSourceTokens(destination: TokenItem)
        case noDestinationTokens(source: TokenItem)
        case validationError(error: ValidationError, context: ValidationErrorContext)
        case notEnoughReceivedAmount(minAmount: Decimal, tokenSymbol: String)
    }

    struct Quote: Hashable {
        let fromAmount: Decimal
        let expectAmount: Decimal
        let highPriceImpact: HighPriceImpactCalculator.Result?
    }

    struct PermissionRequiredState {
        let provider: ExpressProvider
        let policy: BSDKApprovePolicy
        let data: ApproveTransactionData
        let fee: ApproveInputFee
    }

    struct PreviewCEXState {
        let provider: ExpressProvider
        let tokenFeeProvidersManager: TokenFeeProvidersManager
        let subtractFee: SubtractFee
        let isExemptFee: Bool
        let notification: WithdrawalNotification?
    }

    struct SubtractFee {
        let feeTokenItem: TokenItem
        let subtractFee: Decimal
    }

    struct ReadyToSwapState {
        let provider: ExpressProvider
        let tokenFeeProvidersManager: TokenFeeProvidersManager
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

// MARK: - ExpressFee.Option+

extension ExpressFee.Option {
    var feeOption: FeeOption {
        switch self {
        case .fast: .fast
        case .market: .market
        }
    }
}
