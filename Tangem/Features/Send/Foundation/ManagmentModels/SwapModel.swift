//
//  SwapModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemMacro
import TangemFoundation

protocol SwapModelStateProvider: AnyObject {
    var statePublisher: AnyPublisher<SwapModel.ProvidersState, Never> { get }
}

protocol SwapModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
    func performSwapAction()
}

final class SwapModel {
    // MARK: - Data

    private let _sourceToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _receiveToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>

    private let _providersState = CurrentValueSubject<ProvidersState, Never>(.idle)

    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    var externalAmountUpdater: SendAmountExternalUpdater!

    weak var router: SwapModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressAPIProvider: ExpressAPIProvider
    private let analyticsLogger: SendAnalyticsLogger

    private let balanceConverter = BalanceConverter()
    private var updateTask: Task<Void, Never>?

    init(
        sourceToken: SendSourceToken?,
        receiveToken: SendSourceToken?,
        expressManager: ExpressManager,
        expressPairsRepository: ExpressPairsRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAPIProvider: ExpressAPIProvider,
        analyticsLogger: SendAnalyticsLogger
    ) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAPIProvider = expressAPIProvider
        self.analyticsLogger = analyticsLogger

        _sourceToken = .init(sourceToken.map { .success($0) } ?? .loading)
        _receiveToken = .init(receiveToken.map { .success($0) } ?? .loading)
        _amount = .init(.none)

        Task { await initialLoading() }
    }

    deinit {
        ExpressLogger.debug("deinit SwapModel")
    }
}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    func update(sourceAmount: SendAmount?) {
        ExpressLogger.info("Will update source amount to \(sourceAmount as Any)")
        _amount.send(sourceAmount)

        updateTask(loadingType: .rates) { expressManager in
            if sourceAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            return try await expressManager.update(amount: sourceAmount?.crypto, by: .amountChange)
        }
    }

    func update(source wallet: SendSourceToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")

        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendSourceToken) {
        ExpressLogger.info("Will update receive to \(wallet.tokenItem)")

        _receiveToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func swappingPairDidChange() {
        updateTask(loadingType: .providers) { [weak self] expressManager in
            guard let source = self?._sourceToken.value.value, let destination = self?._receiveToken.value.value else {
                ExpressLogger.info("Source / Receive not found")
                let provider: ExpressManagerUpdatingResult = try await expressManager.update(pair: .none)
                return provider
            }

            let pair = ExpressManagerSwappingPair(source: source, destination: destination)
            let provider: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)
            return provider
        }
    }

    func updateTask(loadingType: LoadingType, block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerUpdatingResult?) {
        updateTask?.cancel()
        updateTask = runTask(in: self, code: { input in
            do {
                input._providersState.send(.loading(loadingType))
                let result = try await block(input.expressManager)

                switch result {
                case .none:
                    input.update(providersState: .idle)

                case .some(let updatingResult):
                    let state = try await input.mapToLoadedState(result: updatingResult)
                    input.update(providersState: .loaded(updatingResult, state: state))
                }
            } catch is CancellationError {
                ExpressLogger.debug("updateTask was cancelled")
                // Do nothing
            } catch {
                input.update(providersState: .failure(error))
            }
        })
    }

    func update(providersState: ProvidersState) {
        ExpressLogger.debug(self, "ProvidersState will update to: \(providersState)")

        _providersState.send(providersState)
    }
}

// MARK: - Map

extension SwapModel {
    func mapToLoadedState(result: ExpressManagerUpdatingResult) async throws -> LoadedState {
        if result.providers.isEmpty {
            // No available providers
        }

        guard let selected = result.selected else {
            return .idle
        }

        switch selected.getState() {
        case .idle:
            return .idle

        case .error(let error, .none):
            return .requiredRefresh(occurredError: error, quote: .none)

        case .error(let error, .some(let quote)):
            let quote = try await map(provider: selected.provider, quote: quote)
            return .requiredRefresh(occurredError: error, quote: quote)

        case .restriction(let restriction, .none):
            return .restriction(map(restriction: restriction), quote: .none)

        case .restriction(let restriction, .some(let quote)):
            let quote = try await map(provider: selected.provider, quote: quote)
            return .restriction(map(restriction: restriction), quote: quote)

        case .permissionRequired(let permissionRequired) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: permissionRequired.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .preview(let previewCEX) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: previewCEX.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .ready(let ready) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: ready.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .permissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)

        case .preview(let previewCEX):
            return try await map(provider: selected, previewCEX: previewCEX)

        case .ready(let ready):
            return try await map(provider: selected, ready: ready)
        }
    }

    func map(provider: ExpressProvider, quote: ExpressQuote) async throws -> Quote {
        let highPriceImpact = try await calculateHighPriceImpact(provider: provider, quote: quote)
        return Quote(fromAmount: quote.fromAmount, expectAmount: quote.expectAmount, highPriceImpact: highPriceImpact)
    }

    func calculateHighPriceImpact(provider: ExpressProvider, quote: ExpressQuote?) async throws -> HighPriceImpactCalculator.Result? {
        guard let quote, let source = sourceToken.value?.tokenItem, let destination = receiveToken.value?.tokenItem else {
            return nil
        }

        let priceImpactCalculator = HighPriceImpactCalculator(source: source, destination: destination)
        let result = try await priceImpactCalculator.isHighPriceImpact(provider: provider, quote: quote)
        return result
    }

    func hasPendingTransaction() -> Bool {
        let sendingRestrictionsProvider = sourceToken.value?.sendingRestrictionsProvider
        let hasPendingTransaction = sendingRestrictionsProvider?.sendingRestrictions?.isHasPendingTransaction
        return hasPendingTransaction ?? false
    }

    func map(restriction: ExpressRestriction) -> RestrictionType {
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

    func map(provider: ExpressAvailableProvider, permissionRequired: ExpressProviderManagerState.PermissionRequired) async throws -> LoadedState {
        let source = try sourceToken.get()
        let amount = makeAmount(value: permissionRequired.quote.fromAmount, tokenItem: source.tokenItem)
        let fee = permissionRequired.data.fee

        let quote = try await map(provider: provider.provider, quote: permissionRequired.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let approveFee = ApproveInputFee(feeTokenItem: source.feeTokenItem, fee: fee)
        let permissionRequiredState = PermissionRequiredState(
            quote: quote,
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            fee: approveFee
        )

        return .permissionRequired(permissionRequiredState)
    }

    func map(provider: ExpressAvailableProvider, ready: ExpressProviderManagerState.Ready) async throws -> LoadedState {
        let source = try sourceToken.get()
        let fee = ready.fee

        let amount = makeAmount(value: ready.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: ready.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let readyToSwapState = ReadyToSwapState(quote: quote, data: ready.data, fee: fee)
        return .readyToSwap(readyToSwapState)
    }

    func map(provider: ExpressAvailableProvider, previewCEX: ExpressProviderManagerState.PreviewCEX) async throws -> LoadedState {
        let source = try sourceToken.get()
        let fee = previewCEX.fee

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: previewCEX.quote)

        let withdrawalNotificationProvider = source.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = receiveToken.value as? SendSourceToken {
            let restriction = destination.receivingRestrictionsProvider.restriction(expectAmount: previewCEX.quote.expectAmount)
            switch restriction {
            case .none:
                // All good
                break
            case .notEnoughReceivedAmount(let minAmount):
                return .restriction(
                    .notEnoughReceivedAmount(minAmount: minAmount, tokenSymbol: destination.tokenItem.currencySymbol),
                    quote: quote
                )
            }
        }

        let feeTokenItem = try provider.getTokenFeeProvidersManager().selectedFeeProvider.feeTokenItem
        let subtractFee = SubtractFee(
            feeTokenItem: feeTokenItem,
            subtractFee: previewCEX.subtractFee
        )

        let previewCEXState = PreviewCEXState(
            quote: quote,
            subtractFee: subtractFee,
            fee: fee,
            isExemptFee: source.isExemptFee,
            notification: notification
        )

        return .previewCEX(previewCEXState)
    }

    func validate(amount: Amount, fee: Fee) throws -> RestrictionType? {
        let isFeeCurrency = fee.amount.type == amount.type

        do {
            let source = try sourceToken.get()
            let transactionValidator = source.transactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .notEnoughBalanceForSwapping(requiredAmount: amount.value)
        } catch ValidationError.feeExceedsBalance {
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)
        } catch let error as ValidationError {
            let validationErrorContext = ValidationErrorContext(isFeeCurrency: isFeeCurrency, feeValue: fee.amount.value)
            return .validationError(error: error, context: validationErrorContext)
        } catch {
            ExpressLogger.error(error: "Not expected error: \(error)")
            throw error
        }

        // All good
        return nil
    }

    func makeAmount(value: Decimal, tokenItem: TokenItem) -> BSDKAmount {
        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }
}

// MARK: - Send transaction

extension SwapModel {
    func send() async throws -> TransactionDispatcherResult {
        let source = try sourceToken.get()
        let destination = try receiveToken.get()

        analyticsLogger.logSwapButtonSwap()

        let result = try await {
            switch _providersState.value {
            case .loaded(_, .permissionRequired):
                assertionFailure("Should called sendApproveTransaction()")
                throw ExpressInteractorError.transactionDataNotFound

            case .loaded(let providers, .previewCEX(let previewCEX)):
                let data = try await expressManager.requestData()
                let dispatcher = source.transactionDispatcherProvider.makeCEXTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .cex(data: data, fee: previewCEX.fee))
                analyticsLogger.logSwapTransactionSent(result: result)

                await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)
                try addTransactionToPendingRepository(
                    source: source,
                    destination: destination,
                    provider: providers.selected,
                    data: data,
                    result: result
                )

                return result

            case .loaded(let providers, .readyToSwap(let readyToSwap)):
                let data = readyToSwap.data
                let dispatcher = source.transactionDispatcherProvider.makeDEXTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .dex(data: data, fee: readyToSwap.fee))
                analyticsLogger.logSwapTransactionSent(result: result)
                await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)

                try addTransactionToPendingRepository(
                    source: source,
                    destination: destination,
                    provider: providers.selected,
                    data: data,
                    result: result
                )

                return result

            default:
                throw ExpressInteractorError.transactionDataNotFound
            }
        }()

        _transactionTime.send(.now)
        _transactionURL.send(result.url)

        return result
    }

    func notifyExpressAboutTransactionDidSent(
        source: SendSourceToken,
        data: ExpressTransactionData,
        result: TransactionDispatcherResult
    ) async {
        let expressSentResult = ExpressTransactionSentResult(
            hash: result.hash,
            source: source.tokenItem.expressCurrency,
            address: source.defaultAddressString,
            data: data
        )

        // Ignore error here
        try? await expressAPIProvider.exchangeSent(result: expressSentResult)
    }

    func addTransactionToPendingRepository(
        source: SendSourceToken,
        destination: SendReceiveToken,
        provider: ExpressAvailableProvider?,
        data: ExpressTransactionData,
        result: TransactionDispatcherResult
    ) throws {
        guard let provider else {
            throw ExpressInteractorError.providerNotFound
        }

        /*
         let feetokenFeeProvidersManager = try provider.getTokenFeeProvidersManager()
         let sentTransactionData = SentExpressTransactionData(
             result: result,
             source: source as! ExpressInteractorSourceWallet,
             destination: destination as! ExpressInteractorDestinationWallet,
             fee: feetokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee,
             provider: provider.provider,
             date: Date(),
             expressTransactionData: data
         )

         expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData)
          */
    }
}

// MARK: - Initial (pair) loading

extension SwapModel {
    func initialLoading() async {
        do {
            switch (_sourceToken.value, _receiveToken.value) {
            case (.success, .success):
                // All already set
                swappingPairDidChange()

            case (.success(let source), _):
                try await expressPairsRepository.updatePairs(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                _receiveToken.send(.loading)
                let destination: SendSourceToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination)):
                try await expressPairsRepository.updatePairs(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _sourceToken.send(.loading)
                let source: SendSourceToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
                update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _sourceToken.send(.failure(ExpressInteractorError.sourceNotFound))
                _receiveToken.send(.failure(ExpressInteractorError.destinationNotFound))
            }
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Source not found")
            _sourceToken.send(.failure(ExpressDestinationServiceError.sourceNotFound(destination: destination)))

        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _receiveToken.send(.failure(ExpressDestinationServiceError.destinationNotFound(source: source)))

        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")

            if _receiveToken.value.isLoading {
                _receiveToken.send(.failure(error))
            }

            if _sourceToken.value.isLoading {
                _sourceToken.send(.failure(error))
            }
        }
    }
}

// MARK: - SwapModelStateProvider

extension SwapModel: SwapModelStateProvider {
    var statePublisher: AnyPublisher<ProvidersState, Never> {
        _providersState.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SwapTokenSelectorOutput {
    func swapTokenSelectorDidRequestUpdate(sender item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool) {
        let factory = SendSourceTokenFactory(userWalletInfo: item.userWalletInfo, walletModel: item.walletModel)
        let token = factory.makeSourceToken(
            tokenHeaderProvider: SendTokenHeaderProvider(
                userWalletInfo: item.userWalletInfo,
                account: item.walletModel.account,
                flowActionType: .swap
            )
        )

        update(source: token)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool) {
        let factory = SendSourceTokenFactory(userWalletInfo: item.userWalletInfo, walletModel: item.walletModel)
        let token = factory.makeSourceToken(
            tokenHeaderProvider: SendTokenHeaderProvider(
                userWalletInfo: item.userWalletInfo,
                account: item.walletModel.account,
                flowActionType: .swap
            )
        )

        update(receive: token)
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SendSourceTokenInput, SendSourceTokenOutput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> { _sourceToken.value }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _sourceToken.eraseToAnyPublisher()
    }

    func userDidSelect(sourceToken: SendSourceToken) {
        _sourceToken.send(.success(sourceToken))
    }
}

// MARK: - SendSourceTokenAmountInput

extension SwapModel: SendSourceTokenAmountInput, SendSourceTokenAmountOutput {
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

    func sourceAmountDidChanged(amount: SendAmount?) {
        update(sourceAmount: amount)
    }
}

// MARK: - SendReceiveTokenInput, SendReceiveTokenOutput

extension SwapModel: SendReceiveTokenInput, SendReceiveTokenOutput {
    var isReceiveTokenSelectionAvailable: Bool {
        true
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        _receiveToken.value.mapValue { $0 as SendReceiveToken }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _receiveToken.map { $0.mapValue { $0 as SendReceiveToken }}.eraseToAnyPublisher()
    }

    func userDidRequestClearSelection() {
        assertionFailure("SwapModel doesn't support receiving token clearing")
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        guard let receiveToken = receiveToken as? SendSourceToken else {
            return selected(false)
        }

        _receiveToken.send(.success(receiveToken))
        selected(true)
    }
}

// MARK: - SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput

extension SwapModel: SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        mapToReceiveSendAmount(state: _providersState.value)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _providersState
            .filter { $0.filter(loading: [.rates, .providers]) }
            .withWeakCaptureOf(self)
            .map { $0.mapToReceiveSendAmount(state: $1) }
            .eraseToAnyPublisher()
    }

    var highPriceImpact: HighPriceImpactCalculator.Result? {
        get async {
            try? await mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: sourceAmount.value,
                receiveTokenAmount: receiveAmount.value,
                provider: selectedExpressProvider?.value?.provider
            )
        }
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        Publishers.CombineLatest3(
            sourceAmountPublisher.compactMap { $0.value },
            receiveAmountPublisher.compactMap { $0.value },
            selectedExpressProviderPublisher.compactMap { $0?.value?.provider }
        )
        .withWeakCaptureOf(self)
        .setFailureType(to: Error.self)
        .asyncTryMap {
            try await $0.mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: $1.0,
                receiveTokenAmount: $1.1,
                provider: $1.2
            )
        }
        .replaceError(with: nil)
        .eraseToAnyPublisher()
    }

    private func mapToReceiveSendAmount(state: ProvidersState) -> LoadingResult<SendAmount, any Error> {
        switch state {
        case .loading(.rates),
             .loading(.providers) where sourceAmount.value?.crypto != nil:
            return .loading

        case .idle, .loading: // Another loading has to be filtered
            return .failure(SendAmountError.noAmount)

        case .failure(let error):
            return .failure(error)

        case .loaded(let result, _):
            guard let quote = result.selected?.getState().quote else {
                return .failure(SendAmountError.noAmount)
            }

            let fiat = receiveToken.value?.tokenItem.currencyId.flatMap { currencyId in
                balanceConverter.convertToFiat(quote.expectAmount, currencyId: currencyId)
            }
            return .success(.init(type: .typical(crypto: quote.expectAmount, fiat: fiat)))
        }
    }

    private func mapToHighPriceImpactCalculatorResult(
        sourceTokenAmount: SendAmount?,
        receiveTokenAmount: SendAmount?,
        provider: ExpressProvider?
    ) async throws -> HighPriceImpactCalculator.Result? {
        guard let source = sourceToken.value,
              let receive = receiveToken.value,
              let sourceTokenFiatAmount = sourceTokenAmount?.fiat,
              let receiveTokenFiatAmount = receiveTokenAmount?.fiat,
              let provider = provider else {
            return nil
        }

        let impactCalculator = HighPriceImpactCalculator(
            source: source.tokenItem,
            destination: receive.tokenItem
        )

        let result = try await impactCalculator.isHighPriceImpact(
            provider: provider,
            sourceFiatAmount: sourceTokenFiatAmount,
            destinationFiatAmount: receiveTokenFiatAmount
        )

        return result
    }

    func receiveAmountDidChanged(amount: SendAmount?) {}
}

// MARK: - SendSwapProvidersInput

extension SwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        _providersState.value.providers
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        _providersState.compactMap { $0.providers }.eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        mapToLoadingExpressAvailableProvider(providersState: _providersState.value)
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        _providersState
            .filter { $0.filter(loading: [.rates]) }
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadingExpressAvailableProvider(providersState: $1) }
            .eraseToAnyPublisher().eraseToAnyPublisher()
    }

    private func mapToLoadingExpressAvailableProvider(providersState: ProvidersState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch providersState {
        case .idle: return .none
        case .failure(let error): return .failure(error)
        case .loading(.rates): return .loading
        case .loading: return .none
        case .loaded(let result, _): return result.selected.map { .success($0) }
        }
    }
}

// MARK: - SendSwapProvidersOutput

extension SwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        updateTask(loadingType: .provider) { expressManager in
            try await expressManager.updateSelectedProvider(provider: provider)
        }
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension SwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: (any TokenFeeProvidersManager)? {
        selectedExpressProvider?.value?.manager.feeProvider as? TokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        selectedExpressProviderPublisher
            .compactMap { $0?.value?.manager.feeProvider as? TokenFeeProvidersManager }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeInput

extension SwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        tokenFeeProvidersManager?.selectedTokenFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.selectedTokenFeePublisher }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.supportFeeSelectionPublisher }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        _providersState
            // Ignore all loading
            .filter { $0.filter(loading: []) }
            .withWeakCaptureOf(self)
            .map { $0.mapToShouldShowFeeSelectorRow(providersState: $1) }
            .eraseToAnyPublisher().eraseToAnyPublisher()
    }

    private func mapToShouldShowFeeSelectorRow(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, state: .restriction(.notEnoughAmountForFee, _)),
             .loaded(_, state: .previewCEX),
             .loaded(_, state: .readyToSwap):
            return true
        default:
            return false
        }
    }
}

// MARK: - FeeSelectorOutput

extension SwapModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        tokenFeeProvidersManager?.selectedFeeProvider.updateFees()
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        tokenFeeProvidersManager?.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
        tokenFeeProvidersManager?.update(feeOption: feeOption)

        updateTask(loadingType: .fee) { manager in
            try await manager.update(by: .autoUpdate)
        }
    }
}

// MARK: - SwapSummaryInput, SwapSummaryOutput

extension SwapModel: SwapSummaryInput, SwapSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToIsReadyToSend(providersState: $1) }
            .eraseToAnyPublisher()
    }

    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            selectedExpressProviderPublisher.map { $0?.value?.manager.isFeeCurrency ?? true },
            sourceTokenPublisher.compactMap(\.value),
            receiveTokenPublisher.compactMap(\.value),
        )
        .map { $0 && $1.tokenItem.blockchain == $2.tokenItem.blockchain }
        .eraseToAnyPublisher()
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            _isSending,
            _providersState
                .filter { $0.filter(loading: [.autoupdate]) }
                .map { $0.isLoading },
        )
        .map { $0 || $1 }
        .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.selectedFeeProviderPublisher }
            .flatMapLatest { $0.statePublisher.map(\.isLoading) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToSummaryTransactionData(providersState: $1) }
            .eraseToAnyPublisher()
    }

    func userDidRequestSwap() {
        router?.performSwapAction()
    }

    func userDidRequestMaxAmount() {
        guard let balance = sourceToken.value?.availableBalanceProvider.balanceType.loaded else {
            return
        }

        externalAmountUpdater.externalUpdate(amount: balance)
    }

    func userDidRequestSwapSourceAndReceiveToken() {
        guard let source = _sourceToken.value.value, let destination = _receiveToken.value.value else {
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
            return
        }

        _sourceToken.send(.success(destination))
        _receiveToken.send(.success(source))

        swappingPairDidChange()
    }

    private func mapToIsReadyToSend(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, .previewCEX), .loaded(_, .readyToSwap): true
        default: false
        }
    }

    private func mapToSummaryTransactionData(providersState: ProvidersState) -> SendSummaryTransactionData? {
        switch providersState {
        case .loaded(let providers, _):
            guard let provider = providers.selected else {
                return nil
            }

            return .swap(provider: provider.provider)
        default:
            return .none
        }
    }
}

// MARK: - SendFinishInput

extension SwapModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SwapModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isSending.send(true)
        defer { _isSending.send(false) }

        return try await send()
    }
}

// MARK: - SendBaseDataBuilderInput

extension SwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        guard let crypto = sourceAmount.value?.crypto,
              let source = sourceToken.value else {
            return nil
        }

        return BSDKAmount(with: source.tokenItem.blockchain, type: source.tokenItem.amountType, value: crypto)
    }

    var bsdkFee: BSDKFee? {
        selectedFee?.value.value
    }

    var isFeeIncluded: Bool {
        false
    }
}

// MARK: - SendApproveDataBuilderInput

extension SwapModel: SendApproveDataBuilderInput {
    var approveRequestedByExpressProvider: ExpressProvider? {
        guard case .loaded(let loadedResult, _) = _providersState.value else {
            return nil
        }

        return loadedResult.selected?.provider
    }

    var approveViewModelInput: (any ApproveViewModelInput)? { self }

    var approveRequestedWithSelectedPolicy: ApprovePolicy? {
        guard case .loaded(_, state: .permissionRequired(let permissionRequired)) = _providersState.value else {
            return nil
        }

        return permissionRequired.policy
    }
}

// MARK: - ApproveViewModelInput

extension SwapModel: ApproveViewModelInput {
    func updateApprovePolicy(policy: ApprovePolicy) {
        updateTask(loadingType: .fee) { manager in
            try await manager.update(approvePolicy: policy)
        }
    }

    func sendApproveTransaction() async throws {
        guard case .loaded(let loadedResult, state: .permissionRequired(let state)) = _providersState.value else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        guard let allowanceService = sourceToken.value?.allowanceService else {
            throw ExpressInteractorError.allowanceServiceNotFound
        }

        analyticsLogger.logSwapButtonPermissionApprove(policy: state.policy)
        let result = try await allowanceService.sendApproveTransaction(data: state.data)

        ExpressLogger.info("Sent the approve transaction with result: \(result)")
        analyticsLogger.logApproveTransactionSent(
            policy: state.policy,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )

        update(providersState: .loaded(loadedResult, state: .restriction(.hasPendingTransaction, quote: state.quote)))
    }

    var approveFeeValue: LoadingResult<ApproveInputFee, any Error> {
        mapToApproveFeeLoadingValue(state: _providersState.value)
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingResult<ApproveInputFee, any Error>, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .compactMap { interactor, state in
                interactor.mapToApproveFeeLoadingValue(state: state)
            }
            .eraseToAnyPublisher()
    }

    private func mapToApproveFeeLoadingValue(state: ProvidersState) -> LoadingResult<ApproveInputFee, any Error> {
        switch state {
        case .loaded(_, state: .permissionRequired(let state)):
            return .success(state.fee)
        case .loading:
            return .loading
        case .failure(let error), .loaded(_, .requiredRefresh(let error, _)):
            return .failure(error)
        default:
            // As default state
            return .loading
        }
    }
}

// MARK: - NotificationTapDelegate

extension SwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            let tokenFeeProvidersManager = try? selectedExpressProvider?.get().getTokenFeeProvidersManager()
            tokenFeeProvidersManager?.selectedFeeProvider.updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            sourceToken.value?.availableBalanceProvider.balanceType.value.flatMap {
                leaveMinimalAmountOnBalance(amountToLeave: amount, balance: $0)
            }
        case .reduceAmountBy(let amount, _, _):
            _amount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh:
            swappingPairDidChange()
        case .givePermission:
            router?.openApproveSheet()
        case .generateAddresses,
             .backupCard,
             .goToProvider,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .stake,
             .openLink,
             .swap,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support,
             .openCurrency,
             .seedSupportYes,
             .seedSupportNo,
             .seedSupport2Yes,
             .seedSupport2No,
             .unlock,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .closeMobileUpgrade,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .activate,
             .openCloreMigration:
            assertionFailure("Notification tap not handled")
        }
    }

    private func leaveMinimalAmountOnBalance(amountToLeave amount: Decimal, balance: Decimal) {
        var newAmount = balance - amount

        if let fee = selectedFee?.value.value?.amount, sourceToken.value?.tokenItem.amountType == fee.type {
            // In case when fee can be more that amount
            newAmount = max(0, newAmount - fee.value)
        }

        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: newAmount)
    }

    private func reduceAmountBy(_ amount: Decimal, source: Decimal) {
        var newAmount = source - amount

        switch _providersState.value {
        case .loaded(_, state: .previewCEX(let preview)) where preview.subtractFee.subtractFee > 0:
            newAmount = newAmount - preview.subtractFee.subtractFee
        default:
            break
        }

        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: amount)
    }
}

// MARK: - CustomStringConvertible

extension SwapModel: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Inner types

extension SwapModel {
    @CaseFlagable
    enum ProvidersState {
        case idle
        case loading(LoadingType)
        /// Error only for case when all providers didn't loaded
        case failure(Error)
        case loaded(ExpressManagerUpdatingResult, state: LoadedState)

        var providers: [ExpressAvailableProvider] {
            switch self {
            case .loaded(let result, _): result.providers
            default: []
            }
        }

        /// Accepted `loading types` to show some loading UI
        /// Other `loading types` will be filtered
        func filter(loading types: [LoadingType]) -> Bool {
            switch self {
            case .loading(let type): types.contains(type)
            default: true
            }
        }
    }

    enum LoadingType {
        case providers
        case provider
        case rates
        case autoupdate
        case fee
    }

    enum LoadedState {
        case idle
        case requiredRefresh(occurredError: Error, quote: Quote?)
        case restriction(RestrictionType, quote: Quote?)
        case permissionRequired(PermissionRequiredState)
        case previewCEX(PreviewCEXState)
        case readyToSwap(ReadyToSwapState)
    }

    struct Quote: Hashable {
        let fromAmount: Decimal
        let expectAmount: Decimal
        let highPriceImpact: HighPriceImpactCalculator.Result?
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

    struct PermissionRequiredState {
        let quote: Quote
        let policy: BSDKApprovePolicy
        let data: ApproveTransactionData
        let fee: ApproveInputFee
    }

    struct PreviewCEXState {
        let quote: Quote
        let subtractFee: SubtractFee
        let fee: BSDKFee
        let isExemptFee: Bool
        let notification: WithdrawalNotification?
    }

    struct SubtractFee {
        let feeTokenItem: TokenItem
        let subtractFee: Decimal
    }

    struct ReadyToSwapState {
        let quote: Quote
        let data: ExpressTransactionData
        let fee: BSDKFee
    }

    struct TransactionSendResultState {
        let dispatcherResult: TransactionDispatcherResult
        let data: ExpressTransactionData
        let fee: Fee
        let provider: ExpressProvider
    }
}

// MARK: - ExpressAvailableProvider+

extension ExpressAvailableProvider {
    func getTokenFeeProvidersManager() throws -> TokenFeeProvidersManager {
        guard let tokenFeeProvidersManager = manager.feeProvider as? TokenFeeProvidersManager else {
            throw ExpressInteractorError.feeNotFound
        }

        return tokenFeeProvidersManager
    }
}
