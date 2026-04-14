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
    private let pairUpdateHandler: SwapPairUpdateHandler

    private let balanceConverter = BalanceConverter()
    private var autoupdatingTimerSubscription: AnyCancellable?
    private var updateTask: Task<Void, Never>?
    private var lastLoggedRateType: ExpressProviderRateType?

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
        pairUpdateHandler: SwapPairUpdateHandler,
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
        self.pairUpdateHandler = pairUpdateHandler
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
                await self?.initialLoading()
            }
        }

        setupAutoupdatingTimerSubscription()
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

    func setupAutoupdatingTimerSubscription() {
        autoupdatingTimerSubscription = _state
            .withWeakCaptureOf(self)
            .sink { $0.updateAutoupdatingTimer(state: $1) }
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

        _state.value.userAmount = sourceAmount.map { .source($0) }
        if sourceAmount == nil {
            _state.value.complementaryAmount = nil
        }

        updateTask(loadingType: .rates) { [weak self] expressManager in
            if sourceAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            let amountType: ExpressAmountType? = sourceAmount?.crypto.map { .from($0) }
            let result: ExpressManagerUpdatingResult = try await expressManager.update(
                amountType: amountType,
                by: .amountChange
            )

            if let self, let quote = result.selected?.getState().quote {
                _state.value.complementaryAmount = makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId)
            }

            return result
        }
    }

    func update(receiveAmount: SendAmount?) {
        ExpressLogger.info("Will update receive amount to \(receiveAmount as Any)")

        _state.value.userAmount = receiveAmount.map { .receive($0) }
        if receiveAmount == nil {
            _state.value.complementaryAmount = nil
        }

        updateTask(loadingType: .rates) { [weak self] expressManager in
            if receiveAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            let amountType: ExpressAmountType? = receiveAmount?.crypto.map { .to($0) }
            let result: ExpressManagerUpdatingResult = try await expressManager.update(
                amountType: amountType,
                by: .amountChange
            )

            if let self, let quote = result.selected?.getState().quote {
                _state.value.complementaryAmount = makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId)
            }

            return result
        }
    }

    func update(source wallet: SendSwapableToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")
        _state.value.sourceToken = .success(wallet)

        swappingPairDidChange()
    }

    func update(receive wallet: SendReceiveToken) {
        ExpressLogger.info("Will update receive to \(wallet.tokenItem)")
        _state.value.receiveToken = .success(wallet)

        swappingPairDidChange()
    }

    func swappingPairDidChange() {
        let hasAmount = _state.value.effectiveSourceAmount?.crypto != nil || _state.value.effectiveReceiveAmount?.crypto != nil

        updateTask(loadingType: hasAmount ? .rates : .providers) { [weak self] expressManager in
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

            let result = try await pairUpdateHandler.handlePairChange(
                pair: pair,
                source: source,
                destination: destination,
                sourceAmount: state.effectiveSourceAmount?.crypto,
                receiveAmount: state.effectiveReceiveAmount?.crypto
            )

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
        updateTask = runTask(in: self, code: { @MainActor input in
            do {
                input.updatePhase(.loading(loadingType))
                let result = try await block(input.expressManager)

                try Task.checkCancellation()

                switch result {
                case .none:
                    input._state.value.providers = .empty
                    input.updatePhase(.idle)

                case .some(let updatingResult):
                    let phase = try await input.mapToLoadedPhase(result: updatingResult)

                    try Task.checkCancellation()

                    if case .requiredRefresh(let occurredError, _) = phase {
                        input.logSwapError(loadingType: loadingType, error: occurredError)
                    }

                    input._state.value.providers = ProvidersSnapshot(
                        available: updatingResult.providers,
                        selected: updatingResult.selected
                    )
                    input.updatePhase(.loaded(phase))

                    await input.updateRateTypeAndLogIfNeeded()
                }
            } catch is CancellationError {
                ExpressLogger.debug("updateTask was cancelled")
                // Do nothing
            } catch {
                input.logSwapError(loadingType: loadingType, error: error)
                input._state.value.providers = .empty
                input.updatePhase(.error(SwapPhaseError(underlyingError: error, quote: nil)))
            }
        })
    }

    private func updatePhase(_ phase: SwapPhase) {
        ExpressLogger.debug(self, "Phase will update to: \(phase)")
        _state.value.phase = phase
    }

    private func logSwapError(loadingType: SwapLoadingType, error: Error) {
        analyticsLogger.logSendWithSwapError(
            screen: loadingType.analyticsScreenName,
            errorDescription: error.localizedDescription
        )
    }

    private func updateRateTypeAndLogIfNeeded() async {
        let oldRateType = lastLoggedRateType
        let newRateType = await expressManager.getRateType()
        lastLoggedRateType = newRateType

        if newRateType != nil, newRateType != oldRateType {
            analyticsLogger.logSendWithSwapAmountScreenOpened()
        }
    }

    private func applyAmountUpdate(_ update: SwapPairUpdateResult.AmountUpdate) {
        switch update {
        case .setReceiveAmount(let crypto, let currencyId):
            _state.value.complementaryAmount = makeSendAmount(crypto: crypto, currencyId: currencyId)
        case .setSourceAmount(let crypto, let currencyId):
            _state.value.complementaryAmount = makeSendAmount(crypto: crypto, currencyId: currencyId)
        case .clearReceiveAmount:
            _state.value.complementaryAmount = nil
        }
    }
}

// MARK: - Map

extension SwapModel {
    func mapToLoadedPhase(result: ExpressManagerUpdatingResult) async throws -> SwapLoadedPhase {
        if result.providers.isEmpty {
            // No available providers
        }

        guard let selected = result.selected else {
            return .idle
        }

        switch selected.getState() {
        case .idle:
            return .idle

        case .error(_, let quote) where hasPendingTransaction():
            guard let quote else {
                return .restriction(.hasPendingTransaction, quote: .none)
            }

            let mappedQuote = try await map(provider: selected.provider, quote: quote)
            return .restriction(.hasPendingTransaction, quote: mappedQuote)

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

        case .revokeAndPermissionRequired(let permissionRequired) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: permissionRequired.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .revokeAndPermissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)
        }
    }

    func map(provider: ExpressProvider, quote: ExpressQuote) async throws -> Quote {
        let highPriceImpact = try await calculateHighPriceImpact(provider: provider, quote: quote)
        return Quote(fromAmount: quote.fromAmount, expectAmount: quote.expectAmount, highPriceImpact: highPriceImpact)
    }

    func calculateHighPriceImpact(provider: ExpressProvider, quote: ExpressQuote?) async throws -> HighPriceImpactCalculator.Result? {
        guard let quote,
              let source = sourceToken.value?.tokenItem,
              let destination = receiveToken.value?.tokenItem
        else {
            return nil
        }

        let input = HighPriceImpactCalculator.Input(
            provider: provider,
            sourceToken: source,
            destinationToken: destination,
            sourceAmount: quote.fromAmount,
            destinationAmount: quote.expectAmount
        )

        return try await HighPriceImpactCalculator().calculate(input: input)
    }

    func hasPendingTransaction() -> Bool {
        let sendingRestrictionsProvider = _state.value.sourceToken.value?.sendingRestrictionsProvider
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

    func map(
        provider: ExpressAvailableProvider,
        permissionRequired: ExpressProviderManagerState.PermissionRequired
    ) async throws -> SwapLoadedPhase {
        let amount = makeAmount(value: permissionRequired.quote.fromAmount, tokenItem: try sourceToken.get().tokenItem)

        let fee = permissionRequired.fee

        let quote = try await map(provider: provider.provider, quote: permissionRequired.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let permissionRequiredState = PermissionRequiredState(
            quote: quote,
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            approvalFlow: permissionRequired.approvalFlow
        )

        return .permissionRequired(permissionRequiredState)
    }

    func map(provider: ExpressAvailableProvider, ready: ExpressProviderManagerState.Ready) async throws -> SwapLoadedPhase {
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

    func map(provider: ExpressAvailableProvider, previewCEX: ExpressProviderManagerState.PreviewCEX) async throws -> SwapLoadedPhase {
        let source = try _state.value.sourceToken.get()
        let fee = previewCEX.fee

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: previewCEX.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        if let memoRequiredRestriction = try validateMemoRequired() {
            return .restriction(memoRequiredRestriction, quote: quote)
        }

        let withdrawalNotificationProvider = source.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = receiveToken.value as? SendSwapableToken {
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
        let subtractFee = SubtractFee(feeTokenItem: feeTokenItem, subtractFee: previewCEX.subtractFee)

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
        do {
            let source = try _state.value.sourceToken.get()
            let transactionValidator = source.expressTransactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .notEnoughBalanceForSwapping(requiredAmount: amount.value)
        } catch ValidationError.feeExceedsBalance {
            let isFeeCurrency = fee.amount.type == amount.type
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)
        } catch let error as ValidationError {
            return .validationError(error: error)
        } catch {
            ExpressLogger.error(error: "Not expected error: \(error)")
            throw error
        }

        // All good
        return nil
    }

    func validateMemoRequired() throws -> RestrictionType? {
        let receive = try _state.value.receiveToken.get()

        let destination = receive.destination
        switch destination?.destination {
        case .resolved(_, _, memoRequired: true) where destination?.destinationTag == nil:
            return .validationError(error: .destinationMemoRequired)
        default:
            return nil
        }
    }

    func sendComplementaryAmount(for amountType: ExpressAmountType?, quote: ExpressQuote) {
        switch amountType {
        case .from:
            _state.value.complementaryAmount = makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId)
        case .to:
            _state.value.complementaryAmount = makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId)
        case .none:
            break
        }
    }

    func makeSendAmount(crypto: Decimal, currencyId: String?) -> SendAmount {
        let fiat = currencyId.flatMap { balanceConverter.convertToFiat(crypto, currencyId: $0) }
        return SendAmount(type: .typical(crypto: crypto, fiat: fiat))
    }

    func makeAmount(value: Decimal, tokenItem: TokenItem) -> BSDKAmount {
        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }
}

// MARK: - Send transaction

extension SwapModel {
    func send() async throws -> TransactionDispatcherResult {
        let source = try _state.value.sourceToken.get()
        let receive = try receiveToken.get()

        analyticsLogger.logSwapButtonSwap()

        let currentState = _state.value
        let result = try await {
            guard case .loaded(let loadedPhase) = currentState.phase else {
                throw SwapModel.SwapModelError.transactionDataNotFound
            }

            switch loadedPhase {
            case .permissionRequired:
                assertionFailure("Should called sendApproveTransaction()")
                throw SwapModel.SwapModelError.transactionDataNotFound

            case .previewCEX(let previewCEX):
                guard let selected = currentState.providers.selected else {
                    throw SwapModel.SwapModelError.transactionDataNotFound
                }

                let data = try await expressManager.requestData()
                let dispatcher = source.transactionDispatcherProvider.makeCEXTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .cex(data: data, fee: previewCEX.fee))
                analyticsLogger.logSwapTransactionSent(result: result)

                await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)
                addTransactionToPendingRepository(
                    source: source,
                    receive: receive,
                    provider: selected.provider,
                    fee: previewCEX.fee,
                    data: data,
                    result: result
                )

                return result

            case .readyToSwap(let readyToSwap):
                guard let selected = currentState.providers.selected else {
                    throw SwapModel.SwapModelError.transactionDataNotFound
                }
                let data = readyToSwap.data
                let dispatcher = source.transactionDispatcherProvider.makeDEXTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .dex(data: data, fee: readyToSwap.fee))
                analyticsLogger.logSwapTransactionSent(result: result)
                await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)

                addTransactionToPendingRepository(
                    source: source,
                    receive: receive,
                    provider: selected.provider,
                    fee: readyToSwap.fee,
                    data: data,
                    result: result
                )

                return result

            default:
                throw SwapModel.SwapModelError.transactionDataNotFound
            }
        }()

        _transactionTime.send(.now)
        _transactionURL.send(result.url)

        return result
    }

    func notifyExpressAboutTransactionDidSent(
        source: SendSwapableToken,
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
        source: SendSwapableToken,
        receive: SendReceiveToken,
        provider: ExpressProvider,
        fee: BSDKFee,
        data: ExpressTransactionData,
        result: TransactionDispatcherResult
    ) {
        let sentTransactionData = SentSwapTransactionData(
            expressUserWalletId: expressUserWalletId.stringValue,
            result: result,
            source: source,
            receive: receive,
            fee: fee,
            provider: provider,
            date: Date(),
            expressTransactionData: data
        )

        expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData)
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

                // All already set
                swappingPairDidChange()

            case (.success(let source), _):
                await updatePairsIgnoringErrors(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                _state.value.receiveToken = .loading

                let destination: SendSwapableToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination as SendSwapableToken)):
                await updatePairsIgnoringErrors(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _state.value.sourceToken = .loading

                let source: SendSwapableToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
                update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _state.value.sourceToken = .failure(SwapModel.SwapModelError.sourceNotFound)
                _state.value.receiveToken = .failure(SwapModel.SwapModelError.destinationNotFound)
            }
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Source not found")
            _state.value.sourceToken = .failure(ExpressDestinationServiceError.sourceNotFound(destination: destination))

        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _state.value.receiveToken = .failure(ExpressDestinationServiceError.destinationNotFound(source: source))

        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")

            if _state.value.receiveToken.isLoading {
                _state.value.receiveToken = .failure(error)
            }

            if _state.value.sourceToken.isLoading {
                _state.value.sourceToken = .failure(error)
            }
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

        update(source: token)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

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
        _state.value.sourceToken = .success(swapableToken)
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
        _state.value.complementaryAmount = nil
        _state.value.receiveToken = .loading

        swappingPairDidChange()
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
            guard case .loaded(.restriction(let restriction, _)) = state.phase else {
                return nil
            }

            switch restriction {
            case .tooSmallAmountForSwapping(let amount):
                return .tooSmallAmount(amount)
            case .tooBigAmountForSwapping(let amount):
                return .tooBigAmount(amount)
            case .notEnoughBalanceForSwapping:
                return .balanceExceeded
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

    private func mapToLoadingExpressAvailableProvider(state: SwapState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch state.phase {
        case .idle: .none
        case .error(let error): .failure(error.underlyingError)
        case .loading(.rates): .loading
        case .loading: .none
        case .loaded(.idle): .none
        case .loaded: state.providers.selected.map { .success($0) }
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
        Publishers.CombineLatest(
            _state.filter { $0.phase.filter(loading: [.fee]) }.eraseToAnyPublisher(),
            tokenFeeProvidersManagerPublisher
        )
        .withWeakCaptureOf(self)
        .compactMap { $0.mapToSelectedFee(state: $1.0, tokenFeeProvidersManager: $1.1) }
        .eraseToAnyPublisher()
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
            case .loaded(.restriction(.notEnoughAmountForFee, _)):
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
        guard let source = _state.value.sourceToken.value,
              let destination = _state.value.receiveToken.value as? SendSwapableToken else {
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
            return
        }

        _state.value.sourceToken = .success(destination)
        _state.value.receiveToken = .success(source)

        swappingPairDidChange()
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
        _state.value.isSending = true
        defer { _state.value.isSending = false }

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

        _state.value.phase = .loaded(.restriction(.hasPendingApproveTransaction, quote: permState.quote))
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

// MARK: - Inner types

extension SwapModel {
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
        case validationError(error: ValidationError)
        case notEnoughReceivedAmount(minAmount: Decimal, tokenSymbol: String)
    }

    struct PermissionRequiredState {
        let quote: Quote
        let policy: BSDKApprovePolicy
        let data: ApproveTransactionData
        let approvalFlow: ExpressProviderManagerState.ApprovalFlow
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

    enum SwapModelError: String, LocalizedError {
        case feeNotFound
        case allowanceServiceNotFound
        case transactionDataNotFound
        case sourceNotFound
        case destinationNotFound

        var errorDescription: String? { rawValue }
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
