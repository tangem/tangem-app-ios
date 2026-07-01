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

    private var selectedApprovePolicy: BSDKApprovePolicy = .specified

    // MARK: - Dependencies

    var externalAmountUpdater: SendAmountExternalUpdater!

    weak var router: SwapModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let expressManager: ExpressManager
    private let swapRepository: SwapRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressAPIProvider: ExpressAPIProvider
    private let expressUserWalletId: UserWalletId
    private let analyticsLogger: any SendAnalyticsLogger
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
        swapRepository: SwapRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressAPIProvider: ExpressAPIProvider,
        expressUserWalletId: UserWalletId,
        analyticsLogger: any SendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        pairUpdateHandler: SwapPairUpdateHandler,
        balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureChecker,
        swapTokenPairResolver: MainSwapPairResolver? = nil,
        shouldStartInitialLoading: Bool,
    ) {
        self.expressManager = expressManager
        self.swapRepository = swapRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
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
                await self?.initialLoading()
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

private extension SwapModel {
    func autoupdatingRates() {
        updateTask(loadingType: .autoupdate) { manager in
            await manager.update(type: .autoupdate)
        }
    }

    func reloadRates() {
        updateTask(loadingType: .rates) { manager in
            await manager.update(type: .amount)
        }
    }

    func bind() {
        _receiveToken
            .map { $0.value?.tokenItem }
            .pairwise()
            .filter { previous, current in previous == nil && current != nil }
            .asyncMap { [weak self] _ -> ExpressProviderRateType in
                guard let publisher = self?._providersState else { return .float }
                let states = await publisher.dropFirst().values
                for await state in states {
                    if case .loaded(.swap(_, let providers), _) = state, providers.supportedRateTypes.isNotEmpty {
                        return providers.supportedRateTypes.contains(.fixed) ? .fixed : .float
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
        case .loaded(.swap(.some, _), .restriction(.hasPendingTransaction, _)),
             .loaded(.swap(.some, _), .restriction(.hasPendingApproveTransaction, _)),
             .loaded(.swap(.some, _), .previewCEX),
             .loaded(.swap(.some, _), .readyToSwap),
             .loaded(.swap(.some, _), .readyToApproveAndSwap):

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

        update(amount: sourceAmount?.crypto.map { .from($0) })

        _sourceAmount.send(sourceAmount)
        if sourceAmount == nil {
            _receiveAmount.send(nil)
        }
    }

    func update(receiveAmount: SendAmount?) {
        ExpressLogger.info("Will update receive amount to \(receiveAmount as Any)")

        update(amount: receiveAmount?.crypto.map { .to($0) })

        _receiveAmount.send(receiveAmount)
        if receiveAmount == nil {
            _sourceAmount.send(nil)
        }
    }

    private func update(amount: ExpressAmountType?) {
        let loadingType: (ExpressManager) async -> LoadingType = { manager in
            await manager.getCurrentPair()?.isTransfer == true ? .fee : .rates
        }

        updateTask(loadingType: loadingType) { expressManager in
            if amount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            return try await expressManager.update(amountType: amount)
        }
    }

    func update(source wallet: SendSwapableToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")
        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendReceiveToken) {
        ExpressLogger.info("Will update receive to \(wallet.tokenItem)")
        _receiveToken.send(.success(wallet))
        swappingPairDidChange()
    }
}

// MARK: - Private

private extension SwapModel {
    func swappingPairDidChange() {
        let loadingType: (ExpressManager) async -> LoadingType? = { [weak self] _ in
            guard let self else {
                return nil
            }

            return await pairUpdateHandler.updatePairLoadingType(
                source: _sourceToken.value.value,
                destination: _receiveToken.value.value
            )
        }

        updateTask(loadingType: loadingType) { [weak self] expressManager in
            guard let self,
                  let source = _sourceToken.value.value,
                  let destination = _receiveToken.value.value else {
                ExpressLogger.info("Source / Receive not found")
                return try await expressManager.update(pair: .none)
            }

            return try await pairUpdateHandler.updatePair(source: source, destination: destination)
        }
    }

    func updateTask(
        loadingType: LoadingType,
        block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerState
    ) {
        updateTask(loadingType: { _ in loadingType }, block: block)
    }

    func updateTask(
        loadingType: @escaping (ExpressManager) async -> LoadingType?,
        block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerState
    ) {
        updateTask?.cancel()
        updateTask = runTask(in: self) { @MainActor input in
            do {
                if let restrictionProvidersState = try await input.hasSwapBalanceRestrictionProvidersState() {
                    return input.update(providersState: restrictionProvidersState)
                }

                if let type = await loadingType(input.expressManager) {
                    input.update(providersState: .loading(type))
                }

                let state = try await block(input.expressManager)
                try Task.checkCancellation()

                let providersState = try await input.mapToLoadedProvidersState(state: state)
                try Task.checkCancellation()

                await input.updateComplementaryAmount(state: providersState)
                input.update(providersState: providersState)

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

    private func hasSwapBalanceRestrictionProvidersState() async throws -> ProvidersState? {
        guard let sourceToken = sourceToken.value else {
            return nil
        }

        let hasRestriction = try await balanceRestrictionFeatureChecker
            .hasSwapTotalBalanceRestriction(for: sourceToken)

        guard hasRestriction else {
            return nil
        }

        guard let sourceAmount = sourceAmount.value?.crypto, sourceAmount > 0 else {
            return .idle
        }

        // For this kind of restriction we don't show any sign of providers.
        return .loaded(.swap(selected: .none, providers: .empty), state: .restriction(.notEnoughBalanceForSwapping, quote: .none))
    }

    /// A card-linked wallet must not receive funds, so a swap that would credit it is blocked up front
    /// (no providers shown) — even if it was somehow chosen as the destination.
    private func incompleteBackupReceiveTokenRestrictionProvidersState() -> ProvidersState? {
        guard let destination = receiveToken.value as? SendSwapableToken,
              case .incompleteBackup = destination.receivingRestrictionsProvider.restriction(expectAmount: .zero) else {
            return nil
        }

        return .loaded(.swap(selected: .none, providers: .empty), state: .restriction(.incompleteBackup, quote: .none))
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
        case .loaded(.swap(.some, _), .requiredRefresh(let occurredError, _)):
            analyticsLogger.logSwapErrorExpressQuote(
                screen: screen,
                errorDescription: occurredError.localizedDescription
            )
        case .loaded(.swap(.some, _), .restriction(let restriction, _)):
            switch restriction {
            case .tooSmallAmountForSwapping, .notEnoughReceivedAmount:
                analyticsLogger.logSwapErrorMinAmount(screen: screen)
            case .tooBigAmountForSwapping:
                analyticsLogger.logSwapErrorMaxAmount(screen: screen)
            case .notEnoughBalanceForSwapping, .notEnoughAmountForFee, .notEnoughAmountForTxValue, .validationError:
                analyticsLogger.logSwapErrorInsufficientBalance(screen: screen)
            case .hasPendingTransaction, .hasPendingApproveTransaction, .incompleteBackup:
                break
            }
        default:
            break
        }
    }
}

// MARK: - Map

extension SwapModel {
    func mapToLoadedProvidersState(state: ExpressManagerState) async throws -> ProvidersState {
        if let restrictionProvidersState = incompleteBackupReceiveTokenRestrictionProvidersState() {
            return restrictionProvidersState
        }

        switch state {
        case .idle:
            return .idle

        case .transfer where FeatureProvider.isAvailable(.transfers):
            let loadedState = try await mapToReadyToTransferState()
            try Task.checkCancellation()
            return .loaded(state, state: loadedState)

        case .transfer:
            // Toggle is off. Use just no providers state
            return .loaded(.swap(selected: .none, providers: .empty), state: .idle)

        case .swap(.some(let selected), _):
            let loaded = try await mapToLoadedState(selected: selected)
            try Task.checkCancellation()
            return .loaded(state, state: loaded)

        case .swap(.none, _):
            return .loaded(state, state: .idle)
        }
    }

    func mapToLoadedState(selected: ExpressAvailableProvider) async throws -> LoadedState {
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

        case .dexWithApprovePreview(let preview) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: preview.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .permissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)

        case .cexPreview(let previewCEX):
            return try await map(provider: selected, previewCEX: previewCEX)

        case .dexPreview(let dexPreview):
            return try await map(provider: selected, dexPreview: dexPreview)

        case .dexWithApprovePreview(let preview):
            return try await map(provider: selected, dexWithApprovePreview: preview)

        case .revokeAndPermissionRequired(let permissionRequired) where hasPendingTransaction():
            let quote = try await map(provider: selected.provider, quote: permissionRequired.quote)
            return .restriction(.hasPendingTransaction, quote: quote)

        case .revokeAndPermissionRequired(let permissionRequired):
            return try await map(provider: selected, permissionRequired: permissionRequired)
        }
    }

    func mapToReadyToTransferState() async throws -> LoadedState {
        let source = try _sourceToken.value.get()
        let receive = try _receiveToken.value.get()

        guard let amountValue = _sourceAmount.value?.crypto else {
            return .idle
        }

        guard let address = receive.address else {
            throw SwapModelError.destinationNotFound
        }

        do {
            // 1. Validate just amount before fee calculation
            let amount = makeAmount(value: amountValue, tokenItem: source.tokenItem)
            if let restriction = try validate(amount: amount) {
                let quote = Quote(fromAmount: amountValue, expectAmount: amountValue, highPriceImpact: nil)
                return .restriction(restriction, quote: quote)
            }

            source.tokenFeeProvidersManager.update(input: .common(amount: amountValue, destination: address))
            await source.tokenFeeProvidersManager.updateFees().value
            let fee = try source.tokenFeeProvidersManager.selectedTokenFee.value.get()

            // When the whole balance is being sent in the fee currency, subtract the fee from the amount
            let isFeeIncluded = CommonFeeIncludedCalculator(validator: source.transactionValidator).shouldIncludeFee(fee, into: amount)
            let subtractFeeValue = isFeeIncluded ? fee.amount.value : .zero
            let feeTokenItem = source.tokenFeeProvidersManager.selectedFeeProvider.feeTokenItem
            let subtractFee = SubtractFee(feeTokenItem: feeTokenItem, subtractFee: subtractFeeValue)

            let adjustedAmount = makeAmount(value: amountValue - subtractFeeValue, tokenItem: source.tokenItem)
            let quote = Quote(fromAmount: adjustedAmount.value, expectAmount: adjustedAmount.value, highPriceImpact: nil)

            // 2. Validate amount, fee and destination
            // We don't have `extraId` on Tangem addresses
            let destination = DestinationType.address(address, params: nil)
            if let restriction = try await validate(amount: adjustedAmount, fee: fee, quote: quote, destination: destination) {
                return .restriction(restriction, quote: quote)
            }

            let notification = source.withdrawalNotificationProvider?.withdrawalNotification(amount: adjustedAmount, fee: fee)
            let state = ReadyToTransferState(
                quote: quote,
                fee: fee,
                subtractFee: subtractFee,
                destination: address,
                notification: notification
            )
            return .readyToTransfer(state)

        } catch {
            let quote = Quote(fromAmount: amountValue, expectAmount: amountValue, highPriceImpact: nil)
            return .requiredRefresh(occurredError: error, quote: quote)
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
        let quote = try await map(provider: provider.provider, quote: permissionRequired.quote)

        if let restriction = try validate(amount: amount, fee: permissionRequired.fee, quote: quote) {
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

        let isBitcoinDexSwap: Bool = {
            guard case .bitcoin = source.tokenItem.blockchain else { return false }
            return FeatureProvider.isAvailable(.bitcoinDexSwap)
        }()

        let restriction = try isBitcoinDexSwap
            ? validate(amount: amount)
            : validate(amount: amount, fee: fee, quote: quote)

        if let restriction {
            return .restriction(restriction, quote: quote)
        }

        let readyToSwapState = ReadyToSwapState(quote: quote, data: dexPreview.data, fee: fee)
        return .readyToSwap(readyToSwapState)
    }

    func map(
        provider: ExpressAvailableProvider,
        dexWithApprovePreview preview: ExpressProviderManagerState.DEXWithApprovePreview
    ) async throws -> LoadedState {
        let source = try sourceToken.get()
        let fee = preview.combinedFee

        let amount = makeAmount(value: preview.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: preview.quote)

        if let restriction = try validate(amount: amount, fee: fee, quote: quote) {
            return .restriction(restriction, quote: quote)
        }

        let readyToApproveAndSwapState = ReadyToApproveAndSwapState(
            quote: quote,
            data: preview.expressTransactionData,
            fee: fee
        )

        return .readyToApproveAndSwap(readyToApproveAndSwapState)
    }

    func map(provider: ExpressAvailableProvider, previewCEX: ExpressProviderManagerState.CEXPreview) async throws -> LoadedState {
        let source = try _sourceToken.value.get()
        let fee = previewCEX.fee

        let amount = makeAmount(value: previewCEX.quote.fromAmount, tokenItem: source.tokenItem)
        let quote = try await map(provider: provider.provider, quote: previewCEX.quote)

        if let restriction = try validate(amount: amount, fee: fee, quote: quote) {
            return .restriction(restriction, quote: quote)
        }

        let withdrawalNotificationProvider = source.withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

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

    func validate(amount: Amount) throws -> RestrictionType? {
        do {
            let source = try _sourceToken.value.get()
            try source.transactionValidator.validate(amount: amount)
            // All good
            return nil
        } catch {
            return try proceedValidationError(error)
        }
    }

    func validate(amount: Amount, fee: Fee, quote: Quote) throws -> RestrictionType? {
        if let restriction = try validateExpectations(quote: quote) {
            return restriction
        }

        do {
            let source = try _sourceToken.value.get()
            try source.transactionValidator.validate(amount: amount, fee: fee)
            // All good
            return nil
        } catch {
            return try proceedValidationError(error)
        }
    }

    func validate(amount: Amount, fee: Fee, quote: Quote, destination: DestinationType) async throws -> RestrictionType? {
        if let restriction = try validateExpectations(quote: quote) {
            return restriction
        }

        do {
            let source = try _sourceToken.value.get()
            try await source.transactionValidator.validate(amount: amount, fee: fee, destination: destination)
            // All good
            return nil
        } catch {
            return try proceedValidationError(error)
        }
    }

    func validateExpectations(quote: Quote) throws -> RestrictionType? {
        if let memoRequiredRestriction = try validateMemoRequired() {
            return memoRequiredRestriction
        }

        if let receivingRestriction = try validateReceivingRestrictions(receiveAmount: quote.expectAmount) {
            return receivingRestriction
        }

        return nil
    }

    func proceedValidationError(_ error: Error) throws -> RestrictionType? {
        switch error {
        case ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance:
            return .notEnoughBalanceForSwapping
        case ValidationError.feeExceedsBalance(_, _, let isFeeCurrency):
            return .notEnoughAmountForFee(isFeeCurrency: isFeeCurrency)
        case let error as ValidationError:
            return .validationError(error: error)
        case let error:
            ExpressLogger.error(error: "Not expected error: \(error)")
            throw error
        }
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

    func validateReceivingRestrictions(receiveAmount: Decimal) throws -> RestrictionType? {
        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        guard let destination = receiveToken.value as? SendSwapableToken else {
            return nil
        }

        let restriction = destination.receivingRestrictionsProvider.restriction(expectAmount: receiveAmount)
        switch restriction {
        case .none:
            // All good
            return nil
        case .notEnoughReceivedAmount(let minAmount):
            return .notEnoughReceivedAmount(minAmount: minAmount, tokenSymbol: destination.tokenItem.currencySymbol)
        case .incompleteBackup:
            // Defensive: a card-linked destination is normally short-circuited in mapToLoadedProvidersState.
            return .incompleteBackup
        }
    }

    func updateComplementaryAmount(state: ProvidersState) async {
        guard case .loaded(_, let loadedState) = state else {
            return
        }

        let amountType = await expressManager.getAmountType()

        switch (amountType, loadedState.quote) {
        case (.from, .some(let quote)):
            _receiveAmount.send(
                makeSendAmount(crypto: quote.expectAmount, currencyId: receiveToken.value?.tokenItem.currencyId)
            )
        case (.to, .some(let quote)):
            _sourceAmount.send(
                makeSendAmount(crypto: quote.fromAmount, currencyId: sourceToken.value?.tokenItem.currencyId)
            )
        case (.from, .none):
            // No provider quote (e.g. amount below the minimum): show an approximate
            // receive amount from local market quotes instead of a stale / empty value.
            updateReceiveAmountFromLocalQuote()
        case (.to, .none):
            updateSourceAmountFromLocalQuote()
        case (.none, _):
            _sourceAmount.send(nil)
            _receiveAmount.send(nil)
        }
    }

    private func updateReceiveAmountFromLocalQuote() {
        guard let sourceCrypto = _sourceAmount.value?.crypto, sourceCrypto > 0,
              let sourceCurrencyId = sourceToken.value?.tokenItem.currencyId,
              let receiveTokenItem = receiveToken.value?.tokenItem,
              let estimate = localQuoteEstimate(crypto: sourceCrypto, fromCurrencyId: sourceCurrencyId, to: receiveTokenItem) else {
            _receiveAmount.send(nil)
            return
        }

        _receiveAmount.send(makeSendAmount(crypto: estimate, currencyId: receiveTokenItem.currencyId))
    }

    private func updateSourceAmountFromLocalQuote() {
        guard let receiveCrypto = _receiveAmount.value?.crypto, receiveCrypto > 0,
              let receiveCurrencyId = receiveToken.value?.tokenItem.currencyId,
              let sourceTokenItem = sourceToken.value?.tokenItem,
              let estimate = localQuoteEstimate(crypto: receiveCrypto, fromCurrencyId: receiveCurrencyId, to: sourceTokenItem) else {
            _sourceAmount.send(nil)
            return
        }

        _sourceAmount.send(makeSendAmount(crypto: estimate, currencyId: sourceTokenItem.currencyId))
    }

    private func localQuoteEstimate(crypto: Decimal, fromCurrencyId: String, to target: TokenItem) -> Decimal? {
        guard let targetCurrencyId = target.currencyId,
              let fiat = balanceConverter.convertToFiat(crypto, currencyId: fromCurrencyId),
              let estimate = balanceConverter.convertToCryptoFrom(fiatValue: fiat, currencyId: targetCurrencyId) else {
            return nil
        }

        return estimate.rounded(scale: target.decimalCount, roundingMode: .down)
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

        let result = try await {
            switch _providersState.value {
            case .loaded(_, .permissionRequired):
                assertionFailure("Should called sendApproveTransaction()")
                throw SwapModel.SwapModelError.transactionDataNotFound

            case .loaded(_, .readyToTransfer(let transferState)):
                analyticsLogger.logSwapButtonTransfer()

                let amount = makeAmount(value: transferState.quote.fromAmount, tokenItem: source.tokenItem)
                let transaction = try await source.transactionCreator.createTransaction(
                    amount: amount,
                    fee: transferState.fee,
                    destinationAddress: transferState.destination,
                    params: nil
                )

                let dispatcher = source.transactionDispatcherProvider.makeTransferTransactionDispatcher()
                let result = try await dispatcher.send(transaction: .transfer(transaction))
                analyticsLogger.logSwapTransactionSent(result: result)

                return result

            case .loaded(.swap(.some(let selected), _), .previewCEX(let previewCEX)):
                analyticsLogger.logSwapButtonSwap()

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

            case .loaded(.swap(.some(let selected), _), .readyToSwap(let readyToSwap)):
                analyticsLogger.logSwapButtonSwap()

                let dispatcher = source.transactionDispatcherProvider.makeDEXTransactionDispatcher()
                let transaction: TransactionDispatcherTransactionType = .dex(data: readyToSwap.data, fee: readyToSwap.fee)

                return try await sendDEX(
                    source: source,
                    receive: receive,
                    provider: selected.provider,
                    data: readyToSwap.data,
                    fee: readyToSwap.fee,
                    dispatcher: dispatcher,
                    transaction: transaction
                )

            case .loaded(.swap(.some(let selected), _), .readyToApproveAndSwap(let readyToApproveAndSwap)):
                analyticsLogger.logSwapButtonSwap()

                let approveData = try await makeApproveData(source: source, provider: selected)
                let dispatcher = source.transactionDispatcherProvider.makeApproveAndDEXTransactionDispatcher()
                let transaction: TransactionDispatcherTransactionType = .approveAndDex(
                    data: readyToApproveAndSwap.data,
                    fee: readyToApproveAndSwap.fee,
                    approveData: approveData
                )

                return try await sendDEX(
                    source: source,
                    receive: receive,
                    provider: selected.provider,
                    data: readyToApproveAndSwap.data,
                    fee: readyToApproveAndSwap.fee,
                    dispatcher: dispatcher,
                    transaction: transaction
                )

            default:
                throw SwapModel.SwapModelError.transactionDataNotFound
            }
        }()

        _transactionTime.send(.now)
        _transactionURL.send(result.url)

        return result
    }

    private func sendDEX(
        source: SendSwapableToken,
        receive: SendReceiveToken,
        provider: ExpressProvider,
        data: ExpressTransactionData,
        fee: BSDKFee,
        dispatcher: TransactionDispatcher,
        transaction: TransactionDispatcherTransactionType
    ) async throws -> TransactionDispatcherResult {
        let didUpgrade = source.sendYieldModuleHelper?.isUpgradeWrapped(data) == true

        let result = try await dispatcher.send(transaction: transaction)
        analyticsLogger.logSwapTransactionSent(result: result)
        await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)

        if didUpgrade {
            try? await source.sendYieldModuleHelper?.refreshVersionAfterUpgrade()
        }

        addTransactionToPendingRepository(
            source: source,
            receive: receive,
            provider: provider,
            fee: fee,
            data: data,
            result: result
        )

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
            address: data.sourceAddress ?? source.defaultAddressString,
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
    private func initialLoading() async {
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

        if _sourceToken.value.value?.tokenItem != token.tokenItem {
            externalAmountUpdater.externalUpdate(amount: nil)
        }

        preselectedTokenChangeAnalyticsLogger.logIfNeeded(direction: .source, selected: token.tokenItem)
        update(source: token)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) {
        let token = item.makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        if _receiveToken.value.value?.tokenItem != token.tokenItem {
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
            .withWeakCaptureOf(self)
            .map { model, state -> ExchangeAmountRestriction? in
                guard case .loaded(_, let loadedState) = state else {
                    return nil
                }

                switch loadedState {
                case .restriction(.tooSmallAmountForSwapping(let amount, let currencySymbol), _):
                    return .tooSmallAmount(amount, currencySymbol: currencySymbol, currencyId: model.currencyId(forRestrictionSymbol: currencySymbol))
                case .restriction(.tooBigAmountForSwapping(let amount, let currencySymbol), _):
                    return .tooBigAmount(amount, currencySymbol: currencySymbol, currencyId: model.currencyId(forRestrictionSymbol: currencySymbol))
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

    private func currencyId(forRestrictionSymbol symbol: String) -> String? {
        if sourceToken.value?.tokenItem.currencySymbol == symbol {
            return sourceToken.value?.tokenItem.currencyId
        }

        if receiveToken.value?.tokenItem.currencySymbol == symbol {
            return receiveToken.value?.tokenItem.currencyId
        }

        return nil
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToHighPriceImpactCalculatorResult(providersState: $1) }
            .eraseToAnyPublisher()
    }

    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> {
        _providersState
            .filter { !$0.isLoading }
            .withWeakCaptureOf(self)
            .asyncMap { await $0.mapToReceiveAmountApproximate(state: $1) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func mapToAmountResult(state: ProvidersState, amount: SendAmount?) -> LoadingResult<SendAmount, any Error> {
        switch state {
        case .loading(.rates), .loading(.providers):
            return .loading
        default:
            break
        }

        switch amount {
        case .none: return .failure(SendAmountError.noAmount)
        case .some(let amount): return .success(amount)
        }
    }

    private func mapToReceiveAmountApproximate(state: ProvidersState) async -> Bool {
        let amountType = await expressManager.getAmountType()
        switch (state, amountType) {
        case (.loaded(.swap(.some(let selected), _), _), _) where selected.rateType == .fixed:
            return false
        case (.loaded(.transfer, _), _):
            return false
        case (_, .to):
            return false
        default:
            return true
        }
    }

    private func mapToHighPriceImpactCalculatorResult(providersState: ProvidersState) -> HighPriceImpactCalculator.Result? {
        guard case .loaded(_, let state) = providersState else {
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
            .map(\.providers)
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

    var providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never> {
        _providersState
            // Do not clear data in `Publisher` when `.loading`
            .filter { !$0.isLoading }
            .map(\.supportedRateTypes)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var currentRateType: ExpressProviderRateType? {
        selectedRateType(from: _providersState.value)
    }

    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> {
        _providersState
            .filter { !$0.isLoading }
            .withWeakCaptureOf(self)
            .map { $0.selectedRateType(from: $1) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func selectedRateType(from state: ProvidersState) -> ExpressProviderRateType? {
        if case .loaded(.swap(.some(let selected), _), _) = state {
            return selected.rateType
        }
        return nil
    }

    private func mapToLoadingExpressAvailableProvider(providersState: ProvidersState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch providersState {
        case .idle: .none
        case .failure(let error): .failure(error)
        case .loading(.rates): .loading
        case .loading: .none
        case .loaded(_, .idle): .none
        case .loaded(_, .requiredRefresh(let error, _)): .failure(error)
        case .loaded(.swap(let selected, _), _): selected.map { .success($0) }
        case .loaded: .none
        }
    }
}

// MARK: - SendSwapProvidersOutput

extension SwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        updateTask(loadingType: .provider) { expressManager in
            await expressManager.updateSelectedProvider(provider: provider)
        }
    }
}

// MARK: - SwapApproveInput

extension SwapModel: SwapApproveInput {
    var approvePolicy: BSDKApprovePolicy {
        selectedApprovePolicy
    }
}

// MARK: - SwapApproveOutput

extension SwapModel: SwapApproveOutput {
    func userDidSelectApprovePolicy(_ policy: BSDKApprovePolicy) {
        selectedApprovePolicy = policy
    }
}

// MARK: - Approve data

private extension SwapModel {
    func makeApproveData(source: SendSwapableToken, provider: ExpressAvailableProvider) async throws -> ApproveTransactionData {
        guard case .dexWithApprovePreview(let preview) = provider.getState(),
              let allowanceProvider = source.allowanceProvider
        else {
            throw SwapModelError.approveDataNotFound
        }

        return try await allowanceProvider.makeApproveData(
            spender: preview.approveData.approveTransactionData.spender,
            amount: preview.quote.fromAmount,
            policy: selectedApprovePolicy
        )
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension SwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: (any TokenFeeProvidersManager)? {
        mapToTokenFeeProvidersManager(providersState: _providersState.value)
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .compactMap { $0.mapToTokenFeeProvidersManager(providersState: $1) }
            .eraseToAnyPublisher()
    }

    private func mapToTokenFeeProvidersManager(providersState: ProvidersState) -> (any TokenFeeProvidersManager)? {
        switch providersState {
        case .loaded(.swap(.some(let selected), _), _):
            return selected.expressFeeProvider as? TokenFeeProvidersManager
        case .loaded(.transfer, _):
            return _sourceToken.value.value?.tokenFeeProvidersManager
        default:
            return nil
        }
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
            .filter { $0.filter(loading: [.rates, .fee]) }
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

        case .loaded(.swap(.some(let selected), _), _):
            return try? selected.getTokenFeeProvidersManager().selectedFeeProvider.selectedTokenFee

        case .loaded(_, .readyToTransfer):
            return tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee

        default:
            return nil
        }
    }

    private func mapToShouldShowFeeSelectorRow(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, .readyToSwap),
             .loaded(_, .readyToApproveAndSwap),
             .loaded(_, .readyToTransfer):
            return true
        case .loaded(.swap(.some(let selected), _), .restriction(.notEnoughAmountForFee, _)),
             .loaded(.swap(.some(let selected), _), .restriction(.notEnoughAmountForTxValue, _)),
             .loaded(.swap(.some(let selected), _), .restriction(.notEnoughBalanceForSwapping, _)):
            return !selected.getState().isPermissionRequired
        case .loaded(_, .previewCEX(let previewCEX)):
            return !previewCEX.isExemptFee
        case .loading(.rates):
            return false
        case .loading(.fee):
            return true
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
            await manager.update(type: .autoupdate)
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
            let isTransfer = sourceToken.tokenItem.expressCurrency == receiveToken.tokenItem.expressCurrency

            return isMainToken && isSameNetwork && isFeeCurrency && !isTransfer
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
        swapSourceAndReceiveToken()
    }

    private func swapSourceAndReceiveToken() {
        let sourceResult = _sourceToken.value
        let receiveResult = _receiveToken.value

        externalAmountUpdater.externalUpdate(amount: nil)

        switch (sourceResult, receiveResult) {
        case (.success(let source), .success(let destination as SendSwapableToken)):
            _sourceToken.send(.success(destination))
            _receiveToken.send(.success(source))
            swappingPairDidChange()

        case (.success, .success(let destination)):
            _receiveToken.send(.success(destination))
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))

        case (.success(let source), .failure(SwapModelError.tokenSelectionRequired)):
            _receiveToken.send(.success(source))
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))

        case (.failure(SwapModelError.tokenSelectionRequired), .success(let destination as SendSwapableToken)):
            _sourceToken.send(.success(destination))
            _receiveToken.send(.failure(SwapModelError.tokenSelectionRequired))

        case (.failure(SwapModelError.tokenSelectionRequired), .success):
            _sourceToken.send(.failure(SwapModelError.tokenSelectionRequired))
            _receiveToken.send(.failure(SwapModelError.tokenSelectionRequired))

        default:
            ExpressLogger.info("Swap Source and Receive tokens is not possible")
        }
    }

    private func mapToIsReadyToSend(providersState: ProvidersState) -> Bool {
        switch providersState {
        case .loaded(_, .previewCEX(let state)):
            return state.quote.highPriceImpact?.isBlocked != true
        case .loaded(_, .readyToSwap(let state)):
            return state.quote.highPriceImpact?.isBlocked != true
        case .loaded(_, .readyToApproveAndSwap(let state)):
            return state.quote.highPriceImpact?.isBlocked != true
        case .loaded(_, .readyToTransfer):
            return true
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
        case .loaded(.swap(let selected, _), _):
            guard let provider = selected,
                  let sourceTokenItem = _sourceToken.value.value?.tokenItem else {
                return nil
            }

            return .swap(amount: amount, fee: fee, provider: provider.provider, sourceTokenItem: sourceTokenItem)
        case .loaded(_, .readyToTransfer):
            guard let amount else {
                return nil
            }

            return .send(amount: amount, fee: fee)
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
        guard case .loaded(.swap(let selected, _), .permissionRequired(let state)) = _providersState.value else {
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
        guard case .loaded(.swap(let selected, let providers), .permissionRequired(let state)) = _providersState.value else {
            return
        }

        update(providersState: .loaded(
            .swap(selected: selected, providers: providers),
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
        case .refresh where _providersState.value.isFailure:
            swappingPairDidChange()
        case .refresh:
            reloadRates()
        case .givePermission:
            router?.openApproveSheet()
        case .backupErrorSupport:
            if let userWalletInfo = (receiveToken.value as? SendSwapableToken)?.userWalletInfo {
                router?.openBackupErrorSupport(userWalletInfo: userWalletInfo)
            }
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
             .openYieldBoostPromo,
             .yieldBoostPromoLater,
             .addFunds,
             .openGetTangemPay,
             .closeGetTangemPay:
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
        case .loaded(_, .previewCEX(let preview)) where preview.subtractFee.subtractFee > 0:
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
        case .loaded(let state, let loaded):
            "loaded(\(state), state: \(loaded))"
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
        case .readyToTransfer: "readyToTransfer"
        case .readyToSwap: "readyToSwap"
        case .readyToApproveAndSwap: "readyToApproveAndSwap"
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
        case loaded(ExpressManagerState, state: LoadedState)

        var providers: [ExpressAvailableProvider] {
            switch self {
            case .loaded(.swap(.some(let selected), let providers), _):
                providers.availableProviders(rate: selected.rateType)
            default:
                []
            }
        }

        var supportedRateTypes: Set<ExpressProviderRateType> {
            switch self {
            case .loaded(.swap(_, let providers), _): providers.supportedRateTypes
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
        case readyToTransfer(ReadyToTransferState)
        case previewCEX(PreviewCEXState)
        case readyToSwap(ReadyToSwapState)
        case readyToApproveAndSwap(ReadyToApproveAndSwapState)

        var quote: Quote? {
            switch self {
            case .idle: nil
            case .requiredRefresh(_, let quote): quote
            case .restriction(_, let quote): quote
            case .permissionRequired(let state): state.quote
            case .readyToTransfer(let state): state.quote
            case .previewCEX(let state): state.quote
            case .readyToSwap(let state): state.quote
            case .readyToApproveAndSwap(let state): state.quote
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
        case incompleteBackup
    }

    struct PermissionRequiredState {
        let quote: Quote
        let policy: BSDKApprovePolicy
        let data: ApproveTransactionData
        let approvalFlow: ExpressProviderManagerState.ApprovalFlow
    }

    struct ReadyToTransferState {
        let quote: Quote
        let fee: BSDKFee
        let subtractFee: SubtractFee
        let destination: String
        let notification: WithdrawalNotification?
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

    struct ReadyToApproveAndSwapState {
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
        case destinationNotFound
        case tokenSelectionRequired
        case approveDataNotFound

        var errorDescription: String? { rawValue }
    }
}

// MARK: - ExpressAvailableProvider+

extension ExpressAvailableProvider {
    func getTokenFeeProvidersManager() throws -> TokenFeeProvidersManager {
        guard let tokenFeeProvidersManager = expressFeeProvider as? TokenFeeProvidersManager else {
            throw SwapModel.SwapModelError.feeNotFound
        }

        return tokenFeeProvidersManager
    }
}
