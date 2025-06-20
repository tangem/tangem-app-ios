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

    private let userWalletId: String
    private let initialWallet: any WalletModel
    private let destinationWallet: (any WalletModel)?
    private let expressManager: ExpressManager
    private let expressRepository: ExpressRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressAnalyticsLogger: ExpressAnalyticsLogger
    private let expressTransactionBuilder: ExpressTransactionBuilder
    private let expressAPIProvider: ExpressAPIProvider
    private let signer: TangemSigner

    // MARK: - Options

    private let _state: CurrentValueSubject<State, Never> = .init(.idle)
    private let _swappingPair: CurrentValueSubject<SwappingPair, Never>

    private var updateStateTask: Task<Void, Error>?

    init(
        userWalletId: String,
        initialWallet: any WalletModel,
        destinationWallet: (any WalletModel)?,
        expressManager: ExpressManager,
        expressRepository: ExpressRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAnalyticsLogger: ExpressAnalyticsLogger,
        expressTransactionBuilder: ExpressTransactionBuilder,
        expressAPIProvider: ExpressAPIProvider,
        signer: TangemSigner
    ) {
        self.userWalletId = userWalletId
        self.initialWallet = initialWallet
        self.destinationWallet = destinationWallet
        self.expressManager = expressManager
        self.expressRepository = expressRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAnalyticsLogger = expressAnalyticsLogger
        self.expressTransactionBuilder = expressTransactionBuilder
        self.expressAPIProvider = expressAPIProvider
        self.signer = signer

        _swappingPair = .init(
            SwappingPair(
                sender: initialWallet,
                destination: { () -> LoadingValue<any WalletModel> in
                    if let destinationWallet {
                        return .loaded(destinationWallet)
                    }

                    return .loading
                }()
            )
        )

        initialLoading(wallet: initialWallet)
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

    func getSender() -> any WalletModel {
        _swappingPair.value.sender
    }

    func getDestination() -> (any WalletModel)? {
        _swappingPair.value.destination.value
    }

    func getDestinationValue() -> LoadingValue<any WalletModel> {
        _swappingPair.value.destination
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
        guard let destination = getDestination() else {
            log("The destination not found")
            return
        }

        let newPair = SwappingPair(sender: destination, destination: .loaded(_swappingPair.value.sender))
        _swappingPair.value = newPair

        swappingPairDidChange()
    }

    func update(sender wallet: any WalletModel) {
        log("Will update sender to \(wallet)")

        _swappingPair.value.sender = wallet
        swappingPairDidChange()
    }

    func update(destination wallet: any WalletModel) {
        log("Will update destination to \(wallet)")

        _swappingPair.value.destination = .loaded(wallet)
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

    func updateApprovePolicy(policy: ExpressApprovePolicy) {
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
    var approveFeeValue: LoadingValue<Fee> {
        mapToApproveFeeLoadingValue(state: getState()) ?? .failedToLoad(error: CommonError.noData)
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingValue<BlockchainSdk.Fee>, Never> {
        state
            .withWeakCaptureOf(self)
            .compactMap { interactor, state in
                interactor.mapToApproveFeeLoadingValue(state: state)
            }
            .eraseToAnyPublisher()
    }

    private func mapToApproveFeeLoadingValue(state: ExpressInteractor.State) -> LoadingValue<BlockchainSdk.Fee>? {
        switch state {
        case .permissionRequired(let state, _):
            guard let fee = try? state.fees.selectedFee() else {
                return .failedToLoad(error: ExpressInteractorError.feeNotFound)
            }

            return .loaded(fee)
        case .loading:
            return .loading
        case .restriction(.requiredRefresh(let error), _):
            return .failedToLoad(error: error)
        default:
            return nil
        }
    }
}

// MARK: - Send

extension ExpressInteractor {
    func send() async throws -> SentExpressTransactionData {
        guard let destination = getDestination() else {
            throw ExpressInteractorError.destinationNotFound
        }

        logSwapTransactionAnalyticsEvent()

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

        // Ignore error here
        let source = getSender()
        let expressSentResult = ExpressTransactionSentResult(
            hash: result.hash,
            source: source.tokenItem.expressCurrency,
            address: source.defaultAddressString,
            data: result.data
        )
        try? await expressAPIProvider.exchangeSent(result: expressSentResult)

        updateState(.idle)
        let sentTransactionData = SentExpressTransactionData(
            hash: result.hash,
            source: getSender(),
            destination: destination,
            fee: result.fee.amount.value,
            feeOption: getState().fees.selected,
            provider: result.provider,
            date: Date(),
            expressTransactionData: result.data
        )

        logTransactionSentAnalyticsEvent(data: sentTransactionData, signerType: result.signerType)
        expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData, userWalletId: userWalletId)

        return sentTransactionData
    }

    func sendApproveTransaction() async throws {
        guard case .permissionRequired(let state, _) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        let fee = try state.fees.selectedFee()

        logApproveTransactionAnalyticsEvent(policy: state.policy)

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeApproveTransaction(
            wallet: sender,
            data: state.data,
            fee: fee
        )

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))
        ExpressLogger.info("Sent the approve transaction with result: \(result)")
        sender.allowanceProvider.didSendApproveTransaction(for: state.data.spender)
        logApproveTransactionSentAnalyticsEvent(policy: state.policy, signerType: result.signerType)
        updateState(.restriction(.hasPendingApproveTransaction, quote: getState().quote))
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
                if let restriction = await interactor.updatePairsAndLoadDestinationIfNeeded() {
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

        case .restriction(.tooSmallAmount(let minAmount), let quote):
            return .restriction(.tooSmallAmountForSwapping(minAmount: minAmount), quote: quote)

        case .restriction(.tooBigAmount(let maxAmount), let quote):
            return .restriction(.tooBigAmountForSwapping(maxAmount: maxAmount), quote: quote)

        case .restriction(.approveTransactionInProgress, let quote):
            return .restriction(.hasPendingApproveTransaction, quote: quote)

        case .restriction(.insufficientBalance(let requiredAmount), let quote):
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: requiredAmount), quote: quote)

        case .restriction(.feeCurrencyHasZeroBalance, let quote):
            return .restriction(.notEnoughAmountForFee(.idle), quote: quote)

        case .restriction(.feeCurrencyInsufficientBalanceForTxValue(let fee), let quote):
            return .restriction(.notEnoughAmountForTxValue(fee), quote: quote)

        case .permissionRequired(let permissionRequired):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: permissionRequired.quote)
            }

            return try await map(permissionRequired: permissionRequired)

        case .previewCEX(let previewCEX):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: previewCEX.quote)
            }

            return try await map(previewCEX: previewCEX)

        case .ready(let ready):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: ready.quote)
            }

            return try await map(ready: ready)
        }
    }

    func updateState(_ state: State) {
        log("Update state to \(state)")

        if case .restriction(.notEnoughAmountForFee, _) = state {
            Analytics.log(
                event: .swapNoticeNotEnoughFee,
                params: [
                    .token: initialWallet.tokenItem.currencySymbol,
                    .blockchain: initialWallet.tokenItem.blockchain.displayName,
                ]
            )
        }

        _state.send(state)
    }
}

// MARK: - Restriction

private extension ExpressInteractor {
    func hasPendingTransaction() -> Bool {
        if case .hasPendingTransaction = getSender().sendingRestrictions {
            return true
        }

        return false
    }

    func map(permissionRequired: ExpressManagerState.PermissionRequired) async throws -> State {
        let fees = mapToFees(fee: .init(option: .market, variants: .single(permissionRequired.data.fee)))
        let amount = makeAmount(value: permissionRequired.quote.fromAmount)
        let fee = try fees.selectedFee()

        let permissionRequiredState = PermissionRequiredState(
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            fees: fees
        )
        let correctState: State = .permissionRequired(permissionRequiredState, quote: permissionRequired.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(ready: ExpressManagerState.Ready) async throws -> State {
        let fees = mapToFees(fee: ready.fee)
        let fee = try fees.selectedFee()
        let amount = makeAmount(value: ready.quote.fromAmount)

        let readyToSwapState = ReadyToSwapState(data: ready.data, fees: fees)
        let correctState: State = .readyToSwap(readyToSwapState, quote: ready.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(previewCEX: ExpressManagerState.PreviewCEX) async throws -> State {
        let fees = mapToFees(fee: previewCEX.fee)
        let fee = try fees.selectedFee()
        let amount = makeAmount(value: previewCEX.quote.fromAmount)

        let withdrawalNotificationProvider = getSender().withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = getDestination(),
           case .noAccount(_, let amount) = destination.state,
           previewCEX.quote.expectAmount < amount {
            return .restriction(
                .notEnoughReceivedAmount(minAmount: amount, tokenSymbol: destination.tokenItem.currencySymbol),
                quote: previewCEX.quote
            )
        }

        let previewCEXState = PreviewCEXState(subtractFee: previewCEX.subtractFee, fees: fees, notification: notification)
        let correctState: State = .previewCEX(previewCEXState, quote: previewCEX.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func validate(amount: Amount, fee: Fee, correctState: State) async -> State {
        do {
            let transactionValidator = getSender().transactionValidator
            try await transactionValidator.validate(amount: amount, fee: fee, destination: .generate)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: amount.value), quote: correctState.quote)
        } catch ValidationError.feeExceedsBalance {
            return .restriction(.notEnoughAmountForFee(correctState), quote: correctState.quote)
        } catch let error as ValidationError {
            let context = ValidationErrorContext(isFeeCurrency: fee.amount.type == amount.type, feeValue: fee.amount.value)
            return .restriction(.validationError(error: error, context: context), quote: correctState.quote)
        } catch {
            return .restriction(.requiredRefresh(occurredError: error), quote: correctState.quote)
        }

        return correctState
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func sendDEXTransaction(state: ReadyToSwapState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let fee = try state.fees.selectedFee()
        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: state.data, fee: fee)

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        return TransactionSendResultState(hash: result.hash, signerType: result.signerType, data: state.data, fee: fee, provider: provider)
    }

    func sendCEXTransaction(state: PreviewCEXState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let fee = try state.fees.selectedFee()
        let sender = getSender()
        let data = try await expressManager.requestData()

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: data, fee: fee)
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        return TransactionSendResultState(hash: result.hash, signerType: result.signerType, data: data, fee: fee, provider: provider)
    }
}

// MARK: - Changes

private extension ExpressInteractor {
    func swappingPairDidChange() {
        updateTask { interactor in
            guard let destination = interactor.getDestination() else {
                return .restriction(.noDestinationTokens, quote: .none)
            }

            // If we have an amount to we will start the full update
            if let amount = await interactor.expressManager.getAmount(), amount > 0 {
                interactor.updateState(.loading(type: .full))
            }

            let sender = interactor.getSender()
            let pair = ExpressManagerSwappingPair(source: sender, destination: destination)
            let state = try await interactor.expressManager.update(pair: pair)
            return try await interactor.mapState(state: state)
        }
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

                if let error = error as? ExpressAPIError {
                    await logExpressError(error)
                }

                let quote = getState().quote
                updateState(.restriction(.requiredRefresh(occurredError: error), quote: quote))
            }
        }
    }

    func initialLoading(wallet: any WalletModel) {
        updateTask { interactor in
            if let restriction = await interactor.initialLoading(wallet: wallet) {
                return .restriction(restriction, quote: .none)
            }

            return .idle
        }
    }

    func updatePairsAndLoadDestinationIfNeeded() async -> RestrictionType? {
        guard getDestination() == nil else {
            return nil
        }

        let wallet = getSender()
        return await initialLoading(wallet: wallet)
    }

    func initialLoading(wallet: any WalletModel) async -> RestrictionType? {
        do {
            try await expressRepository.updatePairs(for: wallet.tokenItem.expressCurrency)

            if _swappingPair.value.destination.value == nil {
                _swappingPair.value.destination = .loading
                let destination = try await expressDestinationService.getDestination(source: wallet)
                update(destination: destination)
            } else {
                swappingPairDidChange()
            }

            return nil
        } catch ExpressDestinationServiceError.destinationNotFound {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            log("Destination not found")
            _swappingPair.value.destination = .failedToLoad(error: ExpressDestinationServiceError.destinationNotFound)
            return .noDestinationTokens
        } catch {
            log("Get destination failed with error: \(error)")
            _swappingPair.value.destination = .failedToLoad(error: error)
            return .requiredRefresh(occurredError: error)
        }
    }

    func mapToFees(fee: ExpressFee) -> Fees {
        let selected: FeeOption = switch fee.option {
        case .fast: .fast
        case .market: .market
        }

        switch fee.variants {
        case .single(let fee):
            return Fees(selected: selected, fees: [.market: fee])
        case .double(let market, let priority):
            return Fees(selected: selected, fees: [.market: market, .fast: priority])
        }
    }

    func makeAmount(value: Decimal) -> Amount {
        let wallet = getSender()
        return Amount(with: wallet.tokenItem.blockchain, type: wallet.tokenItem.amountType, value: value)
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
        expressAnalyticsLogger.logSwapTransactionAnalyticsEvent(destination: getDestination()?.tokenItem.currencySymbol)
    }

    func logApproveTransactionAnalyticsEvent(policy: ExpressApprovePolicy) {
        expressAnalyticsLogger.logApproveTransactionAnalyticsEvent(policy: policy, destination: getDestination()?.tokenItem.currencySymbol)
    }

    func logApproveTransactionSentAnalyticsEvent(policy: ExpressApprovePolicy, signerType: String) {
        expressAnalyticsLogger.logApproveTransactionSentAnalyticsEvent(policy: policy, signerType: signerType)
    }

    func logExpressError(_ error: ExpressAPIError) async {
        let selectedProvider = await getSelectedProvider()
        expressAnalyticsLogger.logExpressError(error, provider: selectedProvider?.provider)
    }

    func logTransactionSentAnalyticsEvent(data: SentExpressTransactionData, signerType: String) {
        let analyticsFeeType: Analytics.ParameterValue = {
            if getState().fees.isFixed {
                return .transactionFeeFixed
            }

            return data.feeOption.analyticsValue
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: data.source.tokenItem.currencySymbol,
            .blockchain: data.source.tokenItem.blockchain.displayName,
            .feeType: analyticsFeeType.rawValue,
            .walletForm: signerType,
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
    case transactionDataNotFound
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
        case loading(type: RefreshType)
        case restriction(RestrictionType, quote: ExpressQuote?)
        case permissionRequired(PermissionRequiredState, quote: ExpressQuote)
        case previewCEX(PreviewCEXState, quote: ExpressQuote)
        case readyToSwap(ReadyToSwapState, quote: ExpressQuote)

        var fees: Fees {
            switch self {
            case .restriction(.notEnoughAmountForFee(.previewCEX(let state, _)), _):
                return state.fees
            case .restriction(.notEnoughAmountForFee(.readyToSwap(let state, _)), _):
                return state.fees
            case .restriction(.notEnoughAmountForFee(.permissionRequired(let state, _)), _):
                return state.fees
            case .permissionRequired(let state, _):
                return state.fees
            case .previewCEX(let state, _):
                return state.fees
            case .readyToSwap(let state, _):
                return state.fees
            case .idle, .loading, .restriction:
                return Fees(selected: .market, fees: [:])
            }
        }

        var quote: ExpressQuote? {
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
        case notEnoughAmountForFee(_ returnState: State)
        case notEnoughAmountForTxValue(_ estimatedTxValue: Decimal)
        case requiredRefresh(occurredError: Error)
        case noDestinationTokens
        case validationError(error: ValidationError, context: ValidationErrorContext)
        case notEnoughReceivedAmount(minAmount: Decimal, tokenSymbol: String)
    }

    struct PermissionRequiredState {
        let policy: ExpressApprovePolicy
        let data: ApproveTransactionData
        let fees: Fees
    }

    struct PreviewCEXState {
        let subtractFee: Decimal
        let fees: Fees
        let notification: WithdrawalNotification?
    }

    struct ReadyToSwapState {
        let data: ExpressTransactionData
        let fees: Fees
    }

    struct Fees {
        let selected: FeeOption
        let fees: [FeeOption: Fee]
    }

    // Manager models

    struct SwappingPair {
        var sender: any WalletModel
        var destination: LoadingValue<any WalletModel>
    }

    struct TransactionSendResultState {
        let hash: String
        let signerType: String
        let data: ExpressTransactionData
        let fee: Fee
        let provider: ExpressProvider
    }
}

// MARK: - Fees+

extension ExpressInteractor.Fees {
    var isFixed: Bool { fees.count == 1 }

    var isEmpty: Bool { fees.isEmpty }

    func selectedFee() throws -> Fee {
        guard let fee = fees[selected] else {
            throw ExpressInteractorError.feeNotFound
        }

        return fee
    }
}
