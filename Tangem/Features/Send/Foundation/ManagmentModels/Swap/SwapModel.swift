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
import TangemFoundation
import TangemLocalization

protocol SwapModelStateProvider: AnyObject {
    var statePublisher: AnyPublisher<SwapState, Never> { get }
}

final class SwapModel {
    // MARK: - Data

    /// Single source of truth for the swap session state.
    private let _state: CurrentValueSubject<SwapState, Never>

    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()

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
    private let expressUserWalletId: UserWalletId
    private let analyticsLogger: SendAnalyticsLogger
    private let autoupdatingTimer: AutoupdatingTimer
    private let eventHandler: SwapEventHandler

    private let balanceConverter = BalanceConverter()
    private var bag: Set<AnyCancellable> = []
    private var updateTask: Task<Void, Never>?

    private lazy var transactionExecutor = SwapTransactionExecutor(
        expressManager: expressManager,
        expressAPIProvider: expressAPIProvider,
        expressPendingTransactionRepository: expressPendingTransactionRepository,
        expressUserWalletId: expressUserWalletId,
        analyticsLogger: analyticsLogger
    )

    init(
        sourceToken: SendSwapableToken?,
        receiveToken: SendReceiveToken?,
        expressManager: ExpressManager,
        expressPairsRepository: ExpressPairsRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAPIProvider: ExpressAPIProvider,
        expressUserWalletId: UserWalletId,
        analyticsLogger: SendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        eventHandler: SwapEventHandler,
        shouldStartInitialLoading: Bool
    ) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAPIProvider = expressAPIProvider
        self.expressUserWalletId = expressUserWalletId
        self.analyticsLogger = analyticsLogger
        self.autoupdatingTimer = autoupdatingTimer
        self.eventHandler = eventHandler
        _state = .init(SwapState(
            sourceToken: sourceToken.map { .success($0) } ?? .loading,
            receiveToken: receiveToken.map { .success($0) } ?? .loading,
            userAmount: nil,
            complementaryAmount: nil,
            providers: .empty,
            phase: .idle,
            isSending: false
        ))

        if shouldStartInitialLoading {
            Task.detached { [weak self] in
                if FeatureProvider.isAvailable(.swapPipelineV2) {
                    await self?.initialLoadingV2()
                } else {
                    await self?.initialLoading()
                }
            }
        }

        bind()
    }

    deinit {
        updateTask?.cancel()
        ExpressLogger.debug("deinit SwapModel")
    }
}

// MARK: - Autoupdating

extension SwapModel {
    func autoupdatingRates() {
        updateTask(loadingType: .autoupdate) { [weak self] manager in
            let result: ExpressManagerUpdatingResult = try await manager.update(by: .autoUpdate)

            if let self, let quote = result.selected?.getState().quote {
                let amountType = await manager.getAmountType()
                sendComplementaryAmount(for: amountType, quote: quote)
            }

            return result
        }
    }

    private func bind() {
        _state
            .withWeakCaptureOf(self)
            .sink { $0.updateAutoupdatingTimer(state: $1) }
            .store(in: &bag)
    }

    func updateAutoupdatingTimer(state: SwapState) {
        guard state.providers.selected != nil else {
            autoupdatingTimer.setup(refresh: .none)
            return
        }

        switch state.phase {
        // Use timer to check pending transactions
        case .loaded(.restriction(.hasPendingTransaction, _)),
             .loaded(.restriction(.hasPendingApproveTransaction, _)),
             .loaded(.previewCEX),
             .loaded(.readyToSwap):

            autoupdatingTimer.setup { [weak self] in
                self?.autoupdatingRates()
            }
        default:
            autoupdatingTimer.setup(refresh: .none)
        }
    }
}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    func update(sourceAmount: SendAmount?) {
        ExpressLogger.info("Will update source amount to \(sourceAmount as Any)")

        _state.mutate { $0.userTypedSourceAmount(sourceAmount) }

        refreshQuotesForAmount(debounce: sourceAmount != nil) { [weak self] handler in
            guard self != nil else { return nil }
            return try await handler.sourceAmountChanged(amount: sourceAmount?.crypto)
        }
    }

    func update(receiveAmount: SendAmount?) {
        ExpressLogger.info("Will update receive amount to \(receiveAmount as Any)")

        _state.mutate { $0.userTypedReceiveAmount(receiveAmount) }

        refreshQuotesForAmount(debounce: receiveAmount != nil) { [weak self] handler in
            guard self != nil else { return nil }
            return try await handler.receiveAmountChanged(amount: receiveAmount?.crypto)
        }
    }

    func update(source wallet: SendSwapableToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")
        _state.mutate { $0.setSourceToken(wallet) }

        refreshQuotesForCurrentPair { handler, pair, source, destination, sourceAmount in
            try await handler.sourceTokenChanged(
                pair: pair,
                source: source,
                destination: destination,
                sourceAmount: sourceAmount
            )
        }
    }

    func update(receive wallet: SendReceiveToken) {
        ExpressLogger.info("Will update receive token to \(wallet.tokenItem)")

        _state.mutate { $0.setReceiveToken(wallet) }

        refreshQuotesForCurrentPair { handler, pair, source, destination, sourceAmount in
            try await handler.receiveTokenChanged(
                pair: pair,
                source: source,
                destination: destination,
                sourceAmount: sourceAmount
            )
        }
    }

    /// Same receive token, refreshed destination address (CEX address change).
    /// Re-fetches quotes against the existing pair without disturbing direction or amounts.
    func update(receiveDestination wallet: SendReceiveToken) {
        ExpressLogger.info("Will update receive destination to \(wallet.tokenItem)")

        _state.mutate { $0.setReceiveToken(wallet) }

        refreshQuotesForDestination()
    }

    /// Runs a full-refresh event (source/receive token changed, or pair-validation after major mutation).
    /// Producers a non-nil pair from current state; falls through to `update(pair: .none)` if either token is missing.
    private func refreshQuotesForCurrentPair(
        _ event: @escaping (SwapEventHandler, ExpressManagerSwappingPair, SendSwapableToken, SendReceiveToken, Decimal?) async throws -> SwapEventResult
    ) {
        let hasAmount = _state.value.effectiveSourceAmount?.crypto != nil || _state.value.effectiveReceiveAmount?.crypto != nil
        let loadingType: SwapLoadingType = hasAmount ? .rates : .providers

        updateTask(loadingType: loadingType) { [weak self] expressManager in
            guard let self else {
                return try await expressManager.update(pair: .none)
            }

            let state = _state.value
            guard let source = state.sourceToken.value,
                  let destination = state.receiveToken.value else {
                ExpressLogger.info("Source / Receive not found")
                return try await expressManager.update(pair: .none)
            }

            let pair = ExpressManagerSwappingPair(source: source, destination: destination)
            let result = try await event(eventHandler, pair, source, destination, state.effectiveSourceAmount?.crypto)

            if let amountUpdate = result.amountUpdate {
                applyAmountUpdate(amountUpdate)
            }

            return result.expressResult
        }
    }

    /// Runs a destination-only refresh: re-fetch quotes on the existing pair without disturbing direction or amounts.
    /// Used by `update(receiveDestination:)` when only the destination address changed (not the receive token itself).
    private func refreshQuotesForDestination() {
        // .providers keeps analyticsScreenName as .amount and avoids clearing displayed amounts.
        updateTask(loadingType: .providers) { [weak self] expressManager in
            guard let self else {
                return try await expressManager.update(pair: .none)
            }
            let result = try await eventHandler.destinationAddressChanged()
            if let amountUpdate = result.amountUpdate {
                applyAmountUpdate(amountUpdate)
            }
            return result.expressResult
        }
    }

    /// Runs a refresh-requested event (e.g. from a `.refresh` notification button).
    /// Re-fetches quotes against the existing pair and amount, surfacing fresh provider state.
    private func refreshQuotesNow() {
        updateTask(loadingType: .providers) { [weak self] expressManager in
            guard let self else {
                return try await expressManager.update(pair: .none)
            }
            let result = try await eventHandler.refreshRequested()
            if let amountUpdate = result.amountUpdate {
                applyAmountUpdate(amountUpdate)
            }
            return result.expressResult
        }
    }

    /// Runs an amount-change event (debounced if the amount is non-nil).
    /// Direction was already set synchronously in `_state.userAmount` by the caller.
    private func refreshQuotesForAmount(
        debounce: Bool,
        _ event: @escaping (SwapEventHandler) async throws -> SwapEventResult?
    ) {
        updateTask(loadingType: .rates) { [weak self] _ in
            guard let self else { return nil }
            if debounce {
                try await Task.sleep(for: .seconds(1))
            }
            guard let result = try await event(eventHandler) else {
                return nil
            }
            if let amountUpdate = result.amountUpdate {
                applyAmountUpdate(amountUpdate)
            }
            return result.expressResult
        }
    }

    func updateTask(
        loadingType: SwapLoadingType,
        block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerUpdatingResult?
    ) {
        updateTask?.cancel()
        updateTask = runTask(in: self) { @MainActor input in
            do {
                input.updatePhase(.loading(loadingType))
                let result = try await block(input.expressManager)
                try Task.checkCancellation()
                try await input.applyUpdateResult(result, loadingType: loadingType)
            } catch is CancellationError {
                // Do nothing
                ExpressLogger.debug("updateTask was cancelled")
            } catch {
                input.handleUpdateError(error, loadingType: loadingType)
            }
        }
    }

    @MainActor
    private func applyUpdateResult(
        _ result: ExpressManagerUpdatingResult?,
        loadingType: SwapLoadingType
    ) async throws {
        switch result {
        case .none:
            _state.mutate { $0.setIdleNoProviders() }

        case .some(let updatingResult):
            let mapper = SwapPhaseMapper(
                sourceToken: _state.value.sourceToken,
                receiveToken: _state.value.receiveToken
            )
            let phase = try await mapper.mapToLoadedPhase(result: updatingResult)

            try Task.checkCancellation()

            logErrorIfNeeded(phase: phase, loadingType: loadingType)

            let snapshot = ProvidersSnapshot(
                available: updatingResult.providers,
                selected: updatingResult.selected
            )
            _state.mutate { $0.setLoaded(providers: snapshot, phase: phase) }
        }
    }

    private func handleUpdateError(_ error: any Error, loadingType: SwapLoadingType) {
        analyticsLogger.logSwapErrorExpressQuote(
            screen: loadingType.analyticsScreenName,
            errorDescription: error.localizedDescription
        )
        _state.mutate { $0.setLoadingError(error) }
    }

    private func updatePhase(_ phase: SwapPhase) {
        ExpressLogger.debug(self, "Phase will update to: \(phase)")
        _state.mutate { $0.setPhase(phase) }
    }

    private func logErrorIfNeeded(phase: SwapLoadedPhase, loadingType: SwapLoadingType) {
        let screen = loadingType.analyticsScreenName
        switch phase {
        case .requiredRefresh(let occurredError, _):
            analyticsLogger.logSwapErrorExpressQuote(
                screen: screen,
                errorDescription: occurredError.localizedDescription
            )
        case .restriction(let restriction, _):
            switch restriction {
            case .tooSmallAmountForSwapping, .notEnoughReceivedAmount:
                analyticsLogger.logSwapErrorMinAmount(screen: screen)
            case .tooBigAmountForSwapping:
                analyticsLogger.logSwapErrorMaxAmount(screen: screen)
            case .notEnoughBalanceForSwapping, .notEnoughAmountForFee, .notEnoughAmountForTxValue, .validationError:
                analyticsLogger.logSwapErrorInsufficientBalance(screen: screen)
            case .hasPendingTransaction, .hasPendingApproveTransaction:
                break
            }
        default:
            break
        }
    }

    private func applyAmountUpdate(_ update: SwapEventResult.AmountUpdate) {
        switch update {
        case .clearComplementary:
            _state.mutate { $0.setComplementaryAmount(nil) }

        case .setComplementary(let crypto):
            // Direction was set synchronously by the caller; complementary is the OTHER side.
            // .source direction → complementary is receive amount → use receive token's currencyId
            // .receive direction → complementary is source amount → use source token's currencyId
            let currencyId: String? = {
                switch _state.value.userAmount {
                case .source: return _state.value.receiveToken.value?.tokenItem.currencyId
                case .receive: return _state.value.sourceToken.value?.tokenItem.currencyId
                case .none: return nil
                }
            }()
            let amount = makeSendAmount(crypto: crypto, currencyId: currencyId)
            _state.mutate { $0.setComplementaryAmount(amount) }

        case .anchorOnSource(let source, let receive, let sourceCurrencyId, let receiveCurrencyId):
            let sourceAmount = makeSendAmount(crypto: source, currencyId: sourceCurrencyId)
            let receiveAmount = makeSendAmount(crypto: receive, currencyId: receiveCurrencyId)
            _state.mutate { $0.anchorOnSource(sourceAmount, complementary: receiveAmount) }

        case .anchorOnReceive(let source, let receive, let sourceCurrencyId, let receiveCurrencyId):
            let sourceAmount = makeSendAmount(crypto: source, currencyId: sourceCurrencyId)
            let receiveAmount = makeSendAmount(crypto: receive, currencyId: receiveCurrencyId)
            _state.mutate { $0.anchorOnReceive(receiveAmount, complementary: sourceAmount) }
        }
    }
}

// MARK: - Helpers

extension SwapModel {
    func sendComplementaryAmount(for amountType: ExpressAmountType?, quote: ExpressQuote) {
        switch amountType {
        case .from:
            let amount = makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId)
            _state.mutate { $0.setComplementaryAmount(amount) }
        case .to:
            let amount = makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId)
            _state.mutate { $0.setComplementaryAmount(amount) }
        case .none:
            break
        }
    }

    func makeSendAmount(crypto: Decimal, currencyId: String?) -> SendAmount {
        let fiat = currencyId.flatMap { balanceConverter.convertToFiat(crypto, currencyId: $0) }
        return SendAmount(type: .typical(crypto: crypto, fiat: fiat))
    }
}

// MARK: - Send transaction

extension SwapModel {
    func send() async throws -> TransactionDispatcherResult {
        let source = try _state.value.sourceToken.get()
        let receive = try receiveToken.get()

        guard case .loaded(let loadedPhase) = _state.value.phase else {
            throw SwapModel.SwapModelError.transactionDataNotFound
        }

        let result = try await transactionExecutor.send(
            source: source,
            receive: receive,
            loadedPhase: loadedPhase,
            selectedProvider: _state.value.providers.selected
        )

        _transactionTime.send(.now)
        _transactionURL.send(result.url)

        return result
    }
}

// MARK: - Initial (pair) loading

extension SwapModel {
    func initialLoading() async {
        do {
            switch (_state.value.sourceToken, _state.value.receiveToken) {
            case (.success(let source), .success):
                try await expressPairsRepository.updatePairs(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                // All already set: route through receiveTokenChanged to validate the pair.
                refreshQuotesForCurrentPair { handler, pair, src, dst, srcAmount in
                    try await handler.receiveTokenChanged(pair: pair, source: src, destination: dst, sourceAmount: srcAmount)
                }

            case (.success(let source), _):
                await updatePairsIgnoringErrors(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                _state.mutate { $0.markReceiveTokenLoading() }

                let destination: SendSwapableToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination as SendSwapableToken)):
                await updatePairsIgnoringErrors(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _state.mutate { $0.markSourceTokenLoading() }

                let source: SendSwapableToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
                update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _state.mutate { $0.failTokenLookup() }
            }
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Source not found")
            _state.mutate { $0.failSourceTokenLoading(ExpressDestinationServiceError.sourceNotFound(destination: destination)) }

        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _state.mutate { $0.failReceiveTokenLoading(ExpressDestinationServiceError.destinationNotFound(source: source)) }

        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")

            _state.mutate { $0.failPendingTokenLoads(error) }
        }
    }

    /// V2 initial loading: avoids source/destination resolution requests and applies the already resolved token state.
    /// Nil tokens (not resolved by `SwapTokenPairResolver`) get `.failure(.tokenSelectionRequired)`.
    /// If both tokens are already resolved, a full refresh is triggered to validate/refresh pair availability,
    /// which may update pairs and perform network-backed repository work.
    private func initialLoadingV2() async {
        switch (_state.value.sourceToken, _state.value.receiveToken) {
        case (.success, .success):
            refreshQuotesForCurrentPair { handler, pair, src, dst, srcAmount in
                try await handler.receiveTokenChanged(pair: pair, source: src, destination: dst, sourceAmount: srcAmount)
            }

        case (.success, _):
            _state.mutate { $0.markReceiveTokenRequiresSelection() }

        case (_, .success):
            _state.mutate { $0.markSourceTokenRequiresSelection() }

        default:
            _state.mutate { $0.markBothTokensRequireSelection() }
        }
    }

    private func updatePairsIgnoringErrors(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async {
        do {
            try await expressPairsRepository.updatePairs(for: wallet, userWalletInfo: userWalletInfo)
        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")
        }
    }
}

// MARK: - SwapModelStateProvider

extension SwapModel: SwapModelStateProvider {
    var statePublisher: AnyPublisher<SwapState, Never> {
        _state.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SwapTokenSelectorOutput {
    func swapTokenSelectorDidRequestUpdate(sender item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        if FeatureProvider.isAvailable(.swapPipelineV2),
           _state.value.sourceToken.value?.tokenItem != token.tokenItem {
            externalAmountUpdater.externalUpdate(amount: nil)
        }

        update(source: token)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        if FeatureProvider.isAvailable(.swapPipelineV2),
           _state.value.receiveToken.value?.tokenItem != token.tokenItem {
            externalAmountUpdater.externalUpdate(amount: nil)
        }

        update(receive: token)
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SendSourceTokenInput, SendSourceTokenOutput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        _state.value.sourceToken.mapValue { $0 as SendSourceToken }
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _state.map(\.sourceToken).map { $0.mapValue { $0 as SendSourceToken } }.eraseToAnyPublisher()
    }

    func userDidSelect(sourceToken: SendSourceToken) {
        guard let swapableToken = sourceToken as? SendSwapableToken else {
            assertionFailure("SwapModel expects SendSwapableToken")
            return
        }
        _state.mutate { $0.setSourceToken(swapableToken) }
    }
}

// MARK: - SendSourceTokenAmountInput

extension SwapModel: SendSourceTokenAmountInput, SendSourceTokenAmountOutput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        guard let amount = _state.value.effectiveSourceAmount else { return .failure(SendAmountError.noAmount) }
        return .success(amount)
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _state.map { state -> LoadingResult<SendAmount, any Error> in
            if state.isLoadingRates { return .loading }
            guard let amount = state.effectiveSourceAmount else { return .failure(SendAmountError.noAmount) }
            return .success(amount)
        }.eraseToAnyPublisher()
    }

    func sourceAmountDidChanged(amount: SendAmount?) {
        update(sourceAmount: amount)
    }
}

// MARK: - SendReceiveTokenInput, SendReceiveTokenOutput

extension SwapModel: SendReceiveTokenInput, SendReceiveTokenOutput {
    var isReceiveTokenSelectionAvailable: Bool {
        guard let sourceToken = _state.value.sourceToken.value else {
            return false
        }

        return sourceToken.swapAvailabilityProvider.isSwapAvailable
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        _state.value.receiveToken.mapValue { $0 as SendReceiveToken }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _state.map(\.receiveToken).map { $0.mapValue { $0 as SendReceiveToken } }.eraseToAnyPublisher()
    }

    func userDidRequestClearSelection() {
        // Endless loading, same as .none value
        _state.mutate { $0.clearReceiveTokenSelection() }

        // Pair invalidated; refreshQuotesForCurrentPair will hit the `Source / Receive not found` guard and
        // call `update(pair: .none)` to clear express-side state.
        refreshQuotesForCurrentPair { handler, pair, src, dst, srcAmount in
            try await handler.receiveTokenChanged(pair: pair, source: src, destination: dst, sourceAmount: srcAmount)
        }
    }

    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void) {
        assertionFailure("userDidRequestSelect(receiveTokenItem:) don't supposed to be called. Call `update(receive:) instead.")
    }
}

// MARK: - SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput

extension SwapModel: SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        guard let amount = _state.value.effectiveReceiveAmount else { return .failure(SendAmountError.noAmount) }
        return .success(amount)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _state.map { state -> LoadingResult<SendAmount, any Error> in
            if state.isLoadingRates { return .loading }
            guard let amount = state.effectiveReceiveAmount else { return .failure(SendAmountError.noAmount) }
            return .success(amount)
        }.eraseToAnyPublisher()
    }

    var exchangeRestrictionPublisher: AnyPublisher<ExchangeAmountRestriction?, Never> {
        _state.map { state -> ExchangeAmountRestriction? in
            guard case .loaded(let loadedPhase) = state.phase else {
                return nil
            }

            switch loadedPhase {
            case .restriction(.tooSmallAmountForSwapping(let amount, _), _):
                return .tooSmallAmount(amount)
            case .restriction(.tooBigAmountForSwapping(let amount, _), _):
                return .tooBigAmount(amount)
            case .restriction(.notEnoughBalanceForSwapping, _):
                return .balanceExceeded
            case .requiredRefresh:
                return .exchangeDataLoadingFailed
            default:
                return nil
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        _state.map { state -> HighPriceImpactCalculator.Result? in
            guard case .loaded(let loadedPhase) = state.phase else { return nil }
            return loadedPhase.quote?.highPriceImpact
        }.eraseToAnyPublisher()
    }

    func receiveAmountDidChange(amount: SendAmount?) {
        update(receiveAmount: amount)
    }
}

// MARK: - SendSwapProvidersInput

extension SwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        _state.value.providers.available
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        _state
            .filter { !$0.phase.isLoading }
            .map(\.providers.available)
            .eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        mapToLoadingExpressAvailableProvider(state: _state.value)
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        _state
            .filter { $0.phase.filter(loading: [.rates]) }
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadingExpressAvailableProvider(state: $1) }
            .eraseToAnyPublisher()
    }

    var currentRateType: ExpressProviderRateType? {
        _state.value.currentRateType
    }

    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> {
        _state.map(\.currentRateType).removeDuplicates().eraseToAnyPublisher()
    }

    private func mapToLoadingExpressAvailableProvider(state: SwapState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch state.phase {
        case .idle: .none
        case .error(let error): .failure(error.underlyingError)
        case .loading(.rates): .loading
        case .loading: .none
        case .loaded(.idle): .none
        case .loaded(.requiredRefresh(let error, _)): .failure(error)
        case .loaded: state.providers.selected.map { .success($0) }
        }
    }
}

// MARK: - SendSwapProvidersOutput

extension SwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        updateTask(loadingType: .provider) { [weak self] expressManager in
            let result: ExpressManagerUpdatingResult = try await expressManager.updateSelectedProvider(provider: provider)

            if let self, let quote = result.selected?.getState().quote {
                let amountType = await expressManager.getAmountType()
                try Task.checkCancellation()
                sendComplementaryAmount(for: amountType, quote: quote)
            }

            return result
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
        Publishers.CombineLatest(
            _state.filter { $0.phase.filter(loading: [.fee]) }.eraseToAnyPublisher(),
            tokenFeeProvidersManagerPublisher
        )
        .withWeakCaptureOf(self)
        .compactMap { $0.mapToSelectedFee(state: $1.0, tokenFeeProvidersManager: $1.1) }
        .eraseToAnyPublisher()
    }

    var supportFeeSelection: Bool {
        tokenFeeProvidersManager?.supportFeeSelection ?? false
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.supportFeeSelectionPublisher }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        _state.map { state -> Bool in
            switch state.phase {
            case .loaded(.readyToSwap):
                return true
            case .loaded(.restriction(.notEnoughAmountForFee, _)),
                 .loaded(.restriction(.notEnoughAmountForTxValue, _)),
                 .loaded(.restriction(.notEnoughBalanceForSwapping, _)):
                guard let selected = state.providers.selected else { return false }
                return !selected.getState().isPermissionRequired
            case .loaded(.previewCEX(let previewCEX)):
                return !previewCEX.isExemptFee
            case .loading(.rates):
                return false
            default:
                return false
            }
        }
        .eraseToAnyPublisher()
    }

    private func mapToSelectedFee(state: SwapState, tokenFeeProvidersManager: TokenFeeProvidersManager) -> TokenFee? {
        switch state.phase {
        case .loading(.fee):
            return TokenFee(
                option: tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.option,
                tokenItem: tokenFeeProvidersManager.selectedFeeProvider.feeTokenItem,
                value: .loading
            )

        case .loaded:
            guard let selected = state.providers.selected else { return nil }
            return try? selected.getTokenFeeProvidersManager().selectedFeeProvider.selectedTokenFee

        default:
            return nil
        }
    }
}

// MARK: - FeeSelectorOutput

extension SwapModel: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        tokenFeeProvidersManager?.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
        tokenFeeProvidersManager?.update(feeOption: feeOption)

        updateTask(loadingType: .fee) { manager in
            try await manager.update(by: .autoUpdate)
        }
    }
}

// MARK: - SendFeeUpdater

extension SwapModel: SendFeeUpdater {
    func updateFees() {
        tokenFeeProvidersManager?.updateFees()
    }
}

// MARK: - SwapSummaryInput, SwapSummaryOutput

extension SwapModel: SwapSummaryInput, SwapSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state
            .filter { !$0.phase.isLoading }
            .map { state -> Bool in
                guard case .loaded(let loadedPhase) = state.phase else { return false }
                switch loadedPhase {
                case .previewCEX(let s): return s.quote.highPriceImpact?.isBlocked != true
                case .readyToSwap(let s): return s.quote.highPriceImpact?.isBlocked != true
                default: return false
                }
            }
            .eraseToAnyPublisher()
    }

    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            tokenFeeProvidersManagerPublisher.map { $0.selectedFeeProvider.feeTokenItem },
            sourceTokenPublisher.compactMap(\.value),
            receiveTokenPublisher.compactMap(\.value),
        )
        .map { feeTokenItem, sourceToken, receiveToken in
            let isMainToken = sourceToken.tokenItem.isBlockchain
            let isSameNetwork = sourceToken.tokenItem.blockchainNetwork == receiveToken.tokenItem.blockchainNetwork
            let isFeeCurrency = feeTokenItem == sourceToken.tokenItem

            return isMainToken && isSameNetwork && isFeeCurrency
        }
        .eraseToAnyPublisher()
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        _state
            .filter { $0.phase.filter(loading: [.autoupdate]) }
            .map(\.phase.isLoading)
            .eraseToAnyPublisher()
    }

    var isActionInProcessing: AnyPublisher<Bool, Never> {
        _state.map(\.isSending).eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.selectedFeeProviderPublisher }
            .flatMapLatest { $0.statePublisher.map(\.isLoading) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers.CombineLatest3(
            _state.filter { !$0.phase.isLoading }.eraseToAnyPublisher(),
            sourceAmountPublisher.map { $0.value?.crypto },
            selectedFeePublisher
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToSummaryTransactionData(state: $1.0, amount: $1.1, fee: $1.2) }
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
        if FeatureProvider.isAvailable(.swapPipelineV2) {
            swapSourceAndReceiveTokenV2()
        } else {
            swapSourceAndReceiveToken()
        }
    }

    private func swapSourceAndReceiveToken() {
        guard let source = _state.value.sourceToken.value,
              let destination = _state.value.receiveToken.value as? SendSwapableToken else {
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
            return
        }

        _state.mutate { $0.swapSourceAndReceive(newSource: destination, newReceive: source) }

        refreshQuotesForCurrentPair { handler, pair, src, dst, srcAmount in
            try await handler.receiveTokenChanged(pair: pair, source: src, destination: dst, sourceAmount: srcAmount)
        }
    }

    private func swapSourceAndReceiveTokenV2() {
        let sourceResult = _state.value.sourceToken
        let receiveResult = _state.value.receiveToken

        externalAmountUpdater.externalUpdate(amount: nil)

        switch (sourceResult, receiveResult) {
        case (.success(let source), .success(let destination)):
            if let swapableDestination = destination as? SendSwapableToken {
                _state.mutate { $0.swapSourceAndReceive(newSource: swapableDestination, newReceive: source) }
                refreshQuotesForCurrentPair { handler, pair, src, dst, srcAmount in
                    try await handler.receiveTokenChanged(pair: pair, source: src, destination: dst, sourceAmount: srcAmount)
                }
            } else {
                _state.mutate { $0.setReceiveTokenAndRequireSourceSelection(destination) }
            }

        case (.success(let source), .failure(SwapModelError.tokenSelectionRequired)):
            _state.mutate { $0.setReceiveTokenAndRequireSourceSelection(source) }

        case (.failure(SwapModelError.tokenSelectionRequired), .success(let destination)):
            _state.mutate { $0.promoteDestinationToSourceAndRequireReceiveSelection(destination) }

        default:
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
        }
    }

    private func mapToSummaryTransactionData(
        state: SwapState,
        amount: Decimal?,
        fee: TokenFee
    ) -> SendSummaryTransactionData? {
        guard case .loaded = state.phase,
              let provider = state.providers.selected else {
            return nil
        }

        return .swap(amount: amount, fee: fee, provider: provider.provider)
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
        _state.map(\.isSending).eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _state.mutate { $0.setIsSending(true) }
        defer { _state.mutate { $0.setIsSending(false) } }

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

// MARK: - ApproveFlowDataProvider, ApproveOutput

extension SwapModel: ApproveFlowDataProvider, ApproveOutput {
    func approveFlowInput() throws -> ApproveFlowInput {
        guard case .loaded(.permissionRequired(let state)) = _state.value.phase else {
            throw SendApproveViewModelInputDataBuilderError.notFound("PermissionRequired state")
        }

        guard let selectedProvider = _state.value.providers.selected?.provider else {
            throw SendApproveViewModelInputDataBuilderError.notFound("Selected provider")
        }

        guard let tokenFeeProvidersManager else {
            throw SendApproveViewModelInputDataBuilderError.notFound("TokenFeeProvidersManager")
        }

        let sourceToken = try _state.value.sourceToken.get()

        return ApproveFlowInput(
            approveAmount: state.quote.fromAmount,
            selectedPolicy: state.policy,
            approveData: state.data,
            approvalFlow: state.approvalFlow,
            sourceToken: sourceToken,
            tokenFeeProvidersManager: tokenFeeProvidersManager,
            localization: state.approvalFlow.makeLocalization(
                providerName: selectedProvider.name,
                currencySymbol: sourceToken.tokenItem.currencySymbol
            )
        )
    }

    func approveDidSendTransaction() {
        guard case .loaded(let loadedPhase) = _state.value.phase,
              case .permissionRequired(let permState) = loadedPhase else {
            return
        }

        _state.mutate { $0.markPendingApproveTransaction(quote: permState.quote) }
    }
}

// MARK: - NotificationTapDelegate

extension SwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            let tokenFeeProvidersManager = try? selectedExpressProvider?.get().getTokenFeeProvidersManager()
            tokenFeeProvidersManager?.updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            sourceToken.value?.availableBalanceProvider.balanceType.value.flatMap {
                leaveMinimalAmountOnBalance(amountToLeave: amount, balance: $0)
            }
        case .reduceAmountBy(let amount, _, _):
            _state.value.effectiveSourceAmount?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh:
            refreshQuotesNow()
        case .givePermission:
            router?.openApproveSheet()
        case .generateAddresses,
             .backupCard,
             .goToProvider,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .stake,
             .openLink,
             .openDeeplink,
             .swap,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support,
             .openCurrency,
             .unlock,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .closeMobileUpgrade,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .activate,
             .openCloreMigration,
             .openDynamicAddressesEnter,
             .openManageTokensAfterWalletSuccessImport:
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

        if case .loaded(.previewCEX(let preview)) = _state.value.phase, preview.subtractFee.subtractFee > 0 {
            newAmount = newAmount - preview.subtractFee.subtractFee
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

// MARK: - ExpressAvailableProvider+

extension ExpressAvailableProvider {
    func getTokenFeeProvidersManager() throws -> TokenFeeProvidersManager {
        guard let tokenFeeProvidersManager = manager.feeProvider as? TokenFeeProvidersManager else {
            throw SwapModel.SwapModelError.feeNotFound
        }

        return tokenFeeProvidersManager
    }
}
