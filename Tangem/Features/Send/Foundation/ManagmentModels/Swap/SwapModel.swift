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
import TangemLocalization

protocol SwapModelStateProvider: AnyObject {
    var statePublisher: AnyPublisher<SwapModel.ProvidersState, Never> { get }
}

final class SwapModel {
    // MARK: - Data

    private let _sourceToken: CurrentValueSubject<LoadingResult<SendSwapableToken, any Error>, Never>
    private let _receiveToken: CurrentValueSubject<LoadingResult<SendReceiveToken, any Error>, Never>

    private let preselectedTokenChangeAnalyticsLogger: SwapPreselectedTokenChangeAnalyticsLogger

    private let _sourceAmount: CurrentValueSubject<SendAmount?, Never>
    private let _receiveAmount: CurrentValueSubject<SendAmount?, Never>

    private let _providersState = CurrentValueSubject<ProvidersState, Never>(.idle)

    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _currentRateType = CurrentValueSubject<ExpressProviderRateType?, Never>(nil)

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
    private let balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureChecker
    private let swapTokenPairResolver: MainSwapPairResolver?

    private let balanceConverter = BalanceConverter()
    private var bag: Set<AnyCancellable> = []
    private var updateTask: Task<Void, Never>?

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
        balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureChecker,
        swapTokenPairResolver: MainSwapPairResolver? = nil,
        shouldStartInitialLoading: Bool,
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
        self.swapTokenPairResolver = swapTokenPairResolver
        self.balanceRestrictionFeatureChecker = balanceRestrictionFeatureChecker

        _sourceToken = .init(sourceToken.map { .success($0) } ?? .loading)
        _receiveToken = .init(receiveToken.map { .success($0) } ?? .loading)
        preselectedTokenChangeAnalyticsLogger = SwapPreselectedTokenChangeAnalyticsLogger(
            preselectedSourceTokenItem: sourceToken?.tokenItem,
            preselectedReceiveTokenItem: receiveToken?.tokenItem,
            analyticsLogger: analyticsLogger
        )
        _sourceAmount = .init(.none)
        _receiveAmount = .init(.none)

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
        ExpressLogger.debug(self, "deinit")
    }
}

// MARK: - Autoupdating

extension SwapModel {
    func autoupdatingRates() {
        updateTask(loadingType: .autoupdate) { [weak self] manager in
            let result: ExpressManagerUpdatingResult = try await manager.update(by: .autoupdate)

            if let self, let quote = result.selected?.getState().quote {
                let amountType = await manager.getAmountType()
                sendComplementaryAmount(for: amountType, quote: quote)
            }

            return result
        }
    }

    private func bind() {
        _receiveToken
            .map { $0.value?.tokenItem }
            .pairwise()
            .filter { previous, current in previous == nil && current != nil }
            .asyncMap { [weak self] _ -> ExpressProviderRateType in
                guard let self else { return .float }
                let states = await _providersState.dropFirst().values
                for await state in states {
                    if case .loaded(_, .some(let provider), _) = state {
                        let hasFixed = provider.supportedRateTypes.contains(.fixed)
                        return hasFixed ? .fixed : .float
                    }
                }
                return .float
            }
            .sink { [weak self] rateType in
                self?.analyticsLogger.logSendWithSwapAmountScreenOpened(rateType: rateType)
            }
            .store(in: &bag)

        _providersState
            .withWeakCaptureOf(self)
            .sink { $0.updateAutoupdatingTimer(state: $1) }
            .store(in: &bag)
    }

    func updateAutoupdatingTimer(state: ProvidersState) {
        switch state {
        // Use timer to check pending transactions
        case .loaded(_, .some, .restriction(.hasPendingTransaction, _)),
             .loaded(_, .some, .restriction(.hasPendingApproveTransaction, _)),
             .loaded(_, .some, .previewCEX),
             .loaded(_, .some, .readyToSwap):

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

        updateTask(loadingType: .rates) { [weak self] expressManager in
            if sourceAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            let amountType: ExpressAmountType? = sourceAmount?.crypto.map { .from($0) }
            let result: ExpressManagerUpdatingResult = try await expressManager.update(amountType: amountType)

            if let self, let quote = result.selected?.getState().quote {
                _receiveAmount.send(makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId))
            }

            return result
        }

        _sourceAmount.send(sourceAmount)

        if sourceAmount == nil {
            _receiveAmount.send(nil)
        }
    }

    func update(receiveAmount: SendAmount?) {
        ExpressLogger.info("Will update receive amount to \(receiveAmount as Any)")

        updateTask(loadingType: .rates) { [weak self] expressManager in
            if receiveAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            let amountType: ExpressAmountType? = receiveAmount?.crypto.map { .to($0) }
            let result: ExpressManagerUpdatingResult = try await expressManager.update(amountType: amountType)

            if let self, let quote = result.selected?.getState().quote {
                _sourceAmount.send(makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId))
            }

            return result
        }

        _receiveAmount.send(receiveAmount)

        if receiveAmount == nil {
            _sourceAmount.send(nil)
        }
    }

    func update(source wallet: SendSwapableToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")
        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendReceiveToken) {
        ExpressLogger.info("Will update receive to \(wallet.tokenItem)")

        let tokenChanged = _receiveToken.value.value?.tokenItem.id != wallet.tokenItem.id

        if tokenChanged {
            _receiveAmount.send(nil)
        }

        _receiveToken.send(.success(wallet))
        swappingPairDidChange(isFullRefresh: tokenChanged)
    }

    func swappingPairDidChange(isFullRefresh: Bool = true) {
        if isFullRefresh {
            _currentRateType.send(nil)
        }
        let hasAmount = _sourceAmount.value?.crypto != nil || _receiveAmount.value?.crypto != nil

        let loadingType: LoadingType
        if isFullRefresh {
            loadingType = hasAmount ? .rates : .providers
        } else {
            // Destination-only change: .providers doesn't clear displayed amounts
            // (only .rates triggers .loading in mapToAmountResult) and keeps
            // analyticsScreenName as .amount instead of .confirmation
            loadingType = .providers
        }

        updateTask(loadingType: loadingType) { [weak self] expressManager in
            guard let self, let source = _sourceToken.value.value,
                  let destination = _receiveToken.value.value else {
                ExpressLogger.info("Source / Receive not found")
                return try await expressManager.update(pair: .none)
            }

            let pair = ExpressManagerSwappingPair(source: source, destination: destination)

            let result = try await pairUpdateHandler.handlePairChange(
                pair: pair,
                source: source,
                destination: destination,
                sourceAmount: _sourceAmount.value?.crypto,
                isFullRefresh: isFullRefresh
            )

            if let amountUpdate = result.amountUpdate {
                applyAmountUpdate(amountUpdate)
            }

            return result.expressResult
        }
    }

    func updateTask(
        loadingType: LoadingType,
        block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerUpdatingResult?
    ) {
        updateTask?.cancel()
        updateTask = runTask(in: self) { @MainActor input in
            do {
                input.update(providersState: .loading(loadingType))

                let result = try await block(input.expressManager)
                try Task.checkCancellation()

                let providersState = try await input.mapToLoadedProvidersState(result: result)
                try Task.checkCancellation()

                input.update(providersState: providersState)
                await input.updateRateType()

            } catch is CancellationError {
                ExpressLogger.info(input, "updateTask was cancelled")
                // Do nothing
            } catch {
                input.update(providersState: .failure(error))
            }
        }
    }

    private func update(providersState: ProvidersState) {
        ExpressLogger.info(self, "ProvidersState will update to: \(providersState)")

        logErrorIfNeeded(providersState: providersState)
        _providersState.send(providersState)
    }

    private func hasSwapBalanceRestriction() async throws -> RestrictionType? {
        guard let sourceAmount = sourceAmount.value?.crypto, sourceAmount > 0 else {
            return nil
        }

        guard let sourceToken = sourceToken.value else {
            return nil
        }

        let hasRestriction = try await balanceRestrictionFeatureChecker.hasSwapTotalBalanceRestriction(for: sourceToken)
        return hasRestriction ? .notEnoughBalanceForSwapping : nil
    }

    private func logErrorIfNeeded(providersState: ProvidersState) {
        // The screen name is derived from the in-flight LoadingType, which only lives on the
        // outgoing `.loading` state. If we're not transitioning from `.loading`, there's nothing to log.
        guard case .loading(let loadingType) = _providersState.value else {
            return
        }

        let screen = loadingType.analyticsScreenName
        switch providersState {
        case .failure(let error):
            analyticsLogger.logSwapErrorExpressQuote(
                screen: screen,
                errorDescription: error.localizedDescription
            )
        case .loaded(_, .some, .requiredRefresh(let occurredError, _)):
            analyticsLogger.logSwapErrorExpressQuote(
                screen: screen,
                errorDescription: occurredError.localizedDescription
            )
        case .loaded(_, .some, .restriction(let restriction, _)):
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

    private func updateRateType() async {
        let newRateType = await expressManager.getRateType()
        _currentRateType.send(newRateType)
    }

    private func applyAmountUpdate(_ update: SwapPairUpdateResult.AmountUpdate) {
        switch update {
        case .setReceiveAmount(let crypto, let currencyId):
            _receiveAmount.send(makeSendAmount(crypto: crypto, currencyId: currencyId))
        case .setSourceAmount(let crypto, let currencyId):
            _sourceAmount.send(makeSendAmount(crypto: crypto, currencyId: currencyId))
        case .clearReceiveAmount:
            _receiveAmount.send(nil)
        }
    }
}

// MARK: - Map

extension SwapModel {
    func mapToLoadedProvidersState(result: ExpressManagerUpdatingResult?) async throws -> ProvidersState {
        switch result {
        case .none:
            return .idle

        case .some(let updatingResult):
            if let restriction = try await hasSwapBalanceRestriction() {
                // For this kind of restriction we don't show selected provider.
                return .loaded(providers: updatingResult.providers, selected: .none, state: .restriction(restriction, quote: .none))
            }

            let state = try await mapToLoadedState(updatingResult: updatingResult)
            try Task.checkCancellation()

            return .loaded(
                providers: updatingResult.providers,
                selected: updatingResult.selected,
                state: state
            )
        }
    }

    func mapToLoadedState(updatingResult: ExpressManagerUpdatingResult) async throws -> LoadedState {
        guard let selected = updatingResult.selected else {
            return .idle
        }

        switch selected.getState() {
        case .idle:
            return .idle

        case .error(_, .none) where hasPendingTransaction():
            return .restriction(.hasPendingTransaction, quote: .none)

        case .error(_, .some(let quote)) where hasPendingTransaction():
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

        case .cexPreview(let previewCEX) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: previewCEX.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .dexPreview(let dexPreview) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: dexPreview.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .permissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)

        case .cexPreview(let previewCEX):
            return try await map(provider: selected, previewCEX: previewCEX)

        case .dexPreview(let dexPreview):
            return try await map(provider: selected, dexPreview: dexPreview)

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
        let sendingRestrictionsProvider = _sourceToken.value.value?.sendingRestrictionsProvider
        let hasPendingTransaction = sendingRestrictionsProvider?.sendingRestrictions?.isHasPendingTransaction
        return hasPendingTransaction ?? false
    }

    func map(restriction: ExpressRestriction) -> RestrictionType {
        switch restriction {
        case .tooSmallAmount(let minAmount, let currencySymbol):
            return .tooSmallAmountForSwapping(minAmount: minAmount, currencySymbol: currencySymbol)

        case .tooBigAmount(let maxAmount, let currencySymbol):
            return .tooBigAmountForSwapping(maxAmount: maxAmount, currencySymbol: currencySymbol)

        case .approveTransactionInProgress:
            return .hasPendingApproveTransaction

        case .insufficientBalance:
            return .notEnoughBalanceForSwapping

        case .feeCurrencyHasZeroBalance(let isFeeCurrency):
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)

        case .feeCurrencyInsufficientBalanceForTxValue(let fee, let isFeeCurrency):
            return .notEnoughAmountForTxValue(fee, isFeeCurrency: isFeeCurrency)
        }
    }

    func map(
        provider: ExpressAvailableProvider,
        permissionRequired: ExpressProviderManagerState.PermissionRequired
    ) async throws -> LoadedState {
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

    func map(provider: ExpressAvailableProvider, dexPreview: ExpressProviderManagerState.DEXPreview) async throws -> LoadedState {
        let source = try sourceToken.get()
        let fee = dexPreview.fee

        let amount = makeAmount(value: dexPreview.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: dexPreview.quote)

        if let restriction = try validate(amount: amount, fee: fee) {
            return .restriction(restriction, quote: quote)
        }

        let readyToSwapState = ReadyToSwapState(quote: quote, data: dexPreview.data, fee: fee)
        return .readyToSwap(readyToSwapState)
    }

    func map(provider: ExpressAvailableProvider, previewCEX: ExpressProviderManagerState.CEXPreview) async throws -> LoadedState {
        let source = try _sourceToken.value.get()
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
            let source = try _sourceToken.value.get()
            let transactionValidator = source.expressTransactionValidator
            try transactionValidator.validate(amount: amount, fee: fee)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .notEnoughBalanceForSwapping
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
        let receive = try _receiveToken.value.get()

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
            _receiveAmount.send(makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId))
        case .to:
            _sourceAmount.send(makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId))
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
        let source = try _sourceToken.value.get()
        let receive = try receiveToken.get()

        analyticsLogger.logSwapButtonSwap()

        let result = try await {
            switch _providersState.value {
            case .loaded(_, _, state: .permissionRequired):
                assertionFailure("Should called sendApproveTransaction()")
                throw SwapModel.SwapModelError.transactionDataNotFound

            case .loaded(_, .some(let selected), state: .previewCEX(let previewCEX)):
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

            case .loaded(_, .some(let selected), state: .readyToSwap(let readyToSwap)):
                let data = readyToSwap.data
                let didUpgrade = source.sendYieldModuleHelper?.isUpgradeWrapped(data) == true

                let dispatcher = source.transactionDispatcherProvider.makeDEXTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .dex(data: data, fee: readyToSwap.fee))
                analyticsLogger.logSwapTransactionSent(result: result)
                await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)

                if didUpgrade {
                    try? await source.sendYieldModuleHelper?.refreshVersionAfterUpgrade()
                }

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
            switch (_sourceToken.value, _receiveToken.value) {
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

                _receiveToken.send(.loading)
                let destination: SendSwapableToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination as SendSwapableToken)):
                await updatePairsIgnoringErrors(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _sourceToken.send(.loading)
                let source: SendSwapableToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
                update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _sourceToken.send(.failure(SwapModel.SwapModelError.sourceNotFound))
                _receiveToken.send(.failure(SwapModel.SwapModelError.destinationNotFound))
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

    private func initialLoadingV2() async {
        switch (_sourceToken.value, _receiveToken.value) {
        case (.success, .success):
            swappingPairDidChange()

        case (.success, _):
            let initialSourceTokenItem = _sourceToken.value.value?.tokenItem

            if let swapTokenPairResolver,
               let resolvedSource = await swapTokenPairResolver.resolve(),
               let currentSource = _sourceToken.value.value,
               // if false that means the user has already changed the source and we respect its choice
               currentSource.tokenItem == initialSourceTokenItem,
               currentSource.tokenItem != resolvedSource.tokenItem {
                update(source: resolvedSource)
            }

            _receiveToken.send(.failure(SwapModelError.tokenSelectionRequired))

        case (_, .success):
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))

        default:
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))
            _receiveToken.send(.failure(SwapModelError.tokenSelectionRequired))
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
    var statePublisher: AnyPublisher<ProvidersState, Never> {
        _providersState.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SwapTokenSelectorOutput {
    func swapTokenSelectorDidRequestUpdate(sender item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        if FeatureProvider.isAvailable(.swapPipelineV2),
           _sourceToken.value.value?.tokenItem != token.tokenItem {
            externalAmountUpdater.externalUpdate(amount: nil)
        }

        preselectedTokenChangeAnalyticsLogger.logIfNeeded(direction: .source, selected: token.tokenItem)
        update(source: token)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        if FeatureProvider.isAvailable(.swapPipelineV2),
           _receiveToken.value.value?.tokenItem != token.tokenItem {
            externalAmountUpdater.externalUpdate(amount: nil)
        }

        preselectedTokenChangeAnalyticsLogger.logIfNeeded(direction: .receive, selected: token.tokenItem)
        update(receive: token)
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SendSourceTokenInput, SendSourceTokenOutput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        _sourceToken.value.mapValue { $0 as SendSourceToken }
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _sourceToken.map { $0.mapValue { $0 as SendSourceToken }}.eraseToAnyPublisher()
    }

    func userDidSelect(sourceToken: SendSourceToken) {
        guard let swapableToken = sourceToken as? SendSwapableToken else {
            assertionFailure("SwapModel expects SendSwapableToken")
            return
        }
        _sourceToken.send(.success(swapableToken))
    }
}

// MARK: - SendSourceTokenAmountInput

extension SwapModel: SendSourceTokenAmountInput, SendSourceTokenAmountOutput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        switch _sourceAmount.value {
        case .none: .failure(SendAmountError.noAmount)
        case .some(let amount): .success(amount)
        }
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        Publishers.CombineLatest(_providersState, _sourceAmount)
            .withWeakCaptureOf(self)
            .map { $0.mapToAmountResult(state: $1.0, amount: $1.1) }
            .eraseToAnyPublisher()
    }

    func sourceAmountDidChanged(amount: SendAmount?) {
        update(sourceAmount: amount)
    }
}

// MARK: - SendReceiveTokenInput, SendReceiveTokenOutput

extension SwapModel: SendReceiveTokenInput, SendReceiveTokenOutput {
    var isReceiveTokenSelectionAvailable: Bool {
        guard let sourceToken = _sourceToken.value.value else {
            return false
        }

        return sourceToken.swapAvailabilityProvider.isSwapAvailable
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        _receiveToken.value.mapValue { $0 as SendReceiveToken }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _receiveToken.map { $0.mapValue { $0 as SendReceiveToken }}.eraseToAnyPublisher()
    }

    func userDidRequestClearSelection() {
        // Endless loading, same as .none value
        _receiveAmount.send(nil)
        _receiveToken.send(.loading)
        swappingPairDidChange()
    }

    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void) {
        assertionFailure("userDidRequestSelect(receiveTokenItem:) don't supposed to be called. Call `update(receive:) instead.")
    }
}

// MARK: - SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput

extension SwapModel: SendReceiveTokenAmountInput, SendReceiveTokenAmountOutput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        switch _receiveAmount.value {
        case .none: .failure(SendAmountError.noAmount)
        case .some(let amount): .success(amount)
        }
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        Publishers.CombineLatest(_providersState, _receiveAmount)
            .withWeakCaptureOf(self)
            .map { $0.mapToAmountResult(state: $1.0, amount: $1.1) }
            .eraseToAnyPublisher()
    }

    var exchangeRestrictionPublisher: AnyPublisher<ExchangeAmountRestriction?, Never> {
        _providersState
            .map { state -> ExchangeAmountRestriction? in
                guard case .loaded(_, _, let loadedState) = state else {
                    return nil
                }

                switch loadedState {
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
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToHighPriceImpactCalculatorResult(providersState: $1) }
            .eraseToAnyPublisher()
    }

    private func mapToAmountResult(state: ProvidersState, amount: SendAmount?) -> LoadingResult<SendAmount, any Error> {
        if case .loading(.rates) = state {
            return .loading
        }

        switch amount {
        case .none: return .failure(SendAmountError.noAmount)
        case .some(let amount): return .success(amount)
        }
    }

    private func mapToHighPriceImpactCalculatorResult(providersState: ProvidersState) -> HighPriceImpactCalculator.Result? {
        guard case .loaded(_, _, let state) = providersState else {
            return nil
        }

        return state.quote?.highPriceImpact
    }

    func receiveAmountDidChange(amount: SendAmount?) {
        update(receiveAmount: amount)
    }
}

// MARK: - SendSwapProvidersInput

extension SwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        _providersState.value.providers
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        _providersState
            // Do not clear data in `Publisher` when `.loading`
            .filter { !$0.isLoading }
            .compactMap { $0.providers }
            .eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        mapToLoadingExpressAvailableProvider(providersState: _providersState.value)
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        _providersState
            .filter { $0.filter(loading: [.rates]) }
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadingExpressAvailableProvider(providersState: $1) }
            .eraseToAnyPublisher()
    }

    var currentRateType: ExpressProviderRateType? {
        _currentRateType.value
    }

    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> {
        _currentRateType.removeDuplicates().eraseToAnyPublisher()
    }

    private func mapToLoadingExpressAvailableProvider(providersState: ProvidersState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch providersState {
        case .idle: .none
        case .failure(let error): .failure(error)
        case .loading(.rates): .loading
        case .loading: .none
        case .loaded(_, _, .idle): .none
        case .loaded(_, _, .requiredRefresh(let error, _)): .failure(error)
        case .loaded(_, let selected, _): selected.map { .success($0) }
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
            _providersState.filter { $0.filter(loading: [.fee]) },
            tokenFeeProvidersManagerPublisher
        )
        .withWeakCaptureOf(self)
        .compactMap { $0.mapToSelectedFee(providersState: $1.0, tokenFeeProvidersManager: $1.1) }
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
        _providersState
            .filter { $0.filter(loading: [.rates]) }
            .withWeakCaptureOf(self)
            .map { $0.mapToShouldShowFeeSelectorRow(providersState: $1) }
            .eraseToAnyPublisher()
    }

    private func mapToSelectedFee(providersState: ProvidersState, tokenFeeProvidersManager: TokenFeeProvidersManager) -> TokenFee? {
        switch providersState {
        case .loading(.fee):
            return TokenFee(
                option: tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee.option,
                tokenItem: tokenFeeProvidersManager.selectedFeeProvider.feeTokenItem,
                value: .loading
            )

        case .loaded(_, .some(let selected), _):
            return try? selected.getTokenFeeProvidersManager().selectedFeeProvider.selectedTokenFee

        default:
            return nil
        }
    }

    private func mapToShouldShowFeeSelectorRow(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, _, state: .readyToSwap):
            return true
        case .loaded(_, .some(let selected), state: .restriction(.notEnoughAmountForFee, _)),
             .loaded(_, .some(let selected), state: .restriction(.notEnoughAmountForTxValue, _)),
             .loaded(_, .some(let selected), state: .restriction(.notEnoughBalanceForSwapping, _)):
            return !selected.getState().isPermissionRequired
        case .loaded(_, _, state: .previewCEX(let previewCEX)):
            return !previewCEX.isExemptFee
        case .loading(.rates):
            return false
        default:
            return false
        }
    }
}

// MARK: - FeeSelectorOutput

extension SwapModel: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        tokenFeeProvidersManager?.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
        tokenFeeProvidersManager?.update(feeOption: feeOption)

        updateTask(loadingType: .fee) { manager in
            try await manager.update(by: .autoupdate)
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
        _providersState
            .filter { !$0.isLoading }
            .withWeakCaptureOf(self)
            .map { $0.mapToIsReadyToSend(providersState: $1) }
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
        _providersState
            .filter { $0.filter(loading: [.autoupdate]) }
            .map { $0.isLoading }
            .eraseToAnyPublisher()
    }

    var isActionInProcessing: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
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
            _providersState.filter { !$0.isLoading },
            sourceAmountPublisher.map { $0.value?.crypto },
            selectedFeePublisher
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToSummaryTransactionData(providersState: $1.0, amount: $1.1, fee: $1.2) }
        .eraseToAnyPublisher()
    }

    func userDidRequestSwap() {
        router?.performSwapAction()
    }

    // [REDACTED_TODO_COMMENT]
    func userDidRequestMaxAmount() {
        guard let balance = sourceToken.value?.availableBalanceProvider.balanceType.loaded else {
            return
        }

        externalAmountUpdater.externalUpdate(amount: balance)
    }

    func userDidRequestSourceAmount(fraction: SwapAmountFraction) {
        guard let token = sourceToken.value,
              let balance = token.availableBalanceProvider.balanceType.loaded else {
            return
        }

        let amount: Decimal = {
            switch fraction {
            case .max:
                return balance
            case .quarter, .half, .threeQuarters:
                let raw = balance * fraction.multiplier
                return raw.rounded(scale: token.tokenItem.decimalCount, roundingMode: .down)
            }
        }()
        externalAmountUpdater.externalUpdate(amount: amount)
    }

    func userDidRequestSwapSourceAndReceiveToken() {
        if FeatureProvider.isAvailable(.swapPipelineV2) {
            swapSourceAndReceiveTokenV2()
        } else {
            swapSourceAndReceiveToken()
        }
    }

    private func swapSourceAndReceiveToken() {
        guard let source = _sourceToken.value.value,
              let destination = _receiveToken.value.value as? SendSwapableToken else {
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
            return
        }

        _sourceToken.send(.success(destination))
        _receiveToken.send(.success(source))

        swappingPairDidChange()
    }

    private func swapSourceAndReceiveTokenV2() {
        let sourceResult = _sourceToken.value
        let receiveResult = _receiveToken.value

        externalAmountUpdater.externalUpdate(amount: nil)

        switch (sourceResult, receiveResult) {
        case (.success(let source), .success(let destination)):
            if let swapableDestination = destination as? SendSwapableToken {
                _sourceToken.send(.success(swapableDestination))
                _receiveToken.send(.success(source))
                swappingPairDidChange()
            } else {
                _receiveToken.send(.success(destination))
                _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))
            }

        case (.success(let source), .failure(SwapModelError.tokenSelectionRequired)):
            _receiveToken.send(.success(source))
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))

        case (.failure(SwapModelError.tokenSelectionRequired), .success(let destination)):
            if let swapableDestination = destination as? SendSwapableToken {
                _sourceToken.send(.success(swapableDestination))
            } else {
                _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))
            }
            _receiveToken.send(.failure(SwapModelError.tokenSelectionRequired))

        default:
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
        }
    }

    private func mapToIsReadyToSend(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, _, state: .previewCEX(let state)):
            return state.quote.highPriceImpact?.isBlocked != true
        case .loaded(_, _, state: .readyToSwap(let state)):
            return state.quote.highPriceImpact?.isBlocked != true
        default:
            return false
        }
    }

    private func mapToSummaryTransactionData(
        providersState: ProvidersState,
        amount: Decimal?,
        fee: TokenFee
    ) -> SendSummaryTransactionData? {
        switch providersState {
        case .loaded(_, let selected, _):
            guard let provider = selected,
                  let sourceTokenItem = _sourceToken.value.value?.tokenItem else {
                return nil
            }

            return .swap(amount: amount, fee: fee, provider: provider.provider, sourceTokenItem: sourceTokenItem)
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

// MARK: - ApproveFlowDataProvider, ApproveOutput

extension SwapModel: ApproveFlowDataProvider, ApproveOutput {
    func approveFlowInput() throws -> ApproveFlowInput {
        guard case .loaded(_, let selected, state: .permissionRequired(let state)) = _providersState.value else {
            throw SendApproveViewModelInputDataBuilderError.notFound("PermissionRequired state")
        }

        guard let selectedProvider = selected?.provider else {
            throw SendApproveViewModelInputDataBuilderError.notFound("Selected provider")
        }

        guard let tokenFeeProvidersManager else {
            throw SendApproveViewModelInputDataBuilderError.notFound("TokenFeeProvidersManager")
        }

        let sourceToken = try _sourceToken.value.get()

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
        guard case .loaded(let providers, let selected, state: .permissionRequired(let state)) = _providersState.value else {
            return
        }

        update(providersState: .loaded(
            providers: providers,
            selected: selected,
            state: .restriction(.hasPendingApproveTransaction, quote: state.quote)
        ))
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
            _sourceAmount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh:
            swappingPairDidChange(isFullRefresh: false)
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
             .openManageTokensAfterWalletSuccessImport,
             .renewTangemPaySession,
             .openPushNotificationsSystemSettings,
             .openYieldBoostPromo:
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
        case .loaded(_, _, state: .previewCEX(let preview)) where preview.subtractFee.subtractFee > 0:
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

// MARK: - ProvidersState + CustomStringConvertible

extension SwapModel.ProvidersState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle:
            "idle"
        case .loading(let type):
            "loading(\(type))"
        case .failure(let error):
            "failure(\(error.localizedDescription))"
        case .loaded(let providers, let selected, let state):
            "loaded(providers: \(providers.count), selected: \(String(describing: selected)), state: \(state))"
        }
    }
}

// MARK: - LoadedState + CustomStringConvertible

extension SwapModel.LoadedState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle: "idle"
        case .requiredRefresh(let error, _): "requiredRefresh(\(error))"
        case .restriction(let restriction, _): "restriction(\(restriction))"
        case .permissionRequired: "permissionRequired"
        case .readyToSwap: "readyToSwap"
        case .previewCEX: "previewCEX"
        }
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
        case loaded(providers: [ExpressAvailableProvider], selected: ExpressAvailableProvider?, state: LoadedState)

        var providers: [ExpressAvailableProvider] {
            switch self {
            case .loaded(let providers, _, _): providers
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

        var analyticsScreenName: Analytics.ParameterValue {
            switch self {
            case .rates, .providers, .provider:
                return .amount
            case .autoupdate, .fee:
                return .confirmation
            }
        }
    }

    enum LoadedState {
        case idle
        case requiredRefresh(occurredError: Error, quote: Quote?)
        case restriction(RestrictionType, quote: Quote?)
        case permissionRequired(PermissionRequiredState)
        case previewCEX(PreviewCEXState)
        case readyToSwap(ReadyToSwapState)

        var quote: Quote? {
            switch self {
            case .idle: nil
            case .requiredRefresh(_, let quote): quote
            case .restriction(_, let quote): quote
            case .permissionRequired(let state): state.quote
            case .previewCEX(let state): state.quote
            case .readyToSwap(let state): state.quote
            }
        }
    }

    struct Quote: Hashable {
        let fromAmount: Decimal
        let expectAmount: Decimal
        let highPriceImpact: HighPriceImpactCalculator.Result?
    }

    enum RestrictionType {
        case tooSmallAmountForSwapping(minAmount: Decimal, currencySymbol: String)
        case tooBigAmountForSwapping(maxAmount: Decimal, currencySymbol: String)
        case hasPendingTransaction
        case hasPendingApproveTransaction
        case notEnoughBalanceForSwapping
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
        case tokenSelectionRequired

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
