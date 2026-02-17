//
//  SendModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol SendModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
    func resetFlow()
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel)
}

final class SendModel {
    // MARK: - Data

    private let _sendingToken: CurrentValueSubject<SendSourceToken, Never>
    private let _receivedToken: CurrentValueSubject<SendReceiveTokenType, Never>
    private let _destination: CurrentValueSubject<SendDestination?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<Result<BSDKTransaction, Error>?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    var externalAmountUpdater: SendAmountExternalUpdater!
    var externalDestinationUpdater: SendDestinationExternalUpdater!
    var informationRelevanceService: InformationRelevanceService!

    weak var router: SendModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let userWalletId: UserWalletId
    private let transactionSigner: TangemSigner
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let analyticsLogger: SendAnalyticsLogger
    private let sendReceiveTokenBuilder: SendReceiveTokenBuilder
    private let sendAlertBuilder: SendAlertBuilder
    private let swapManager: SwapManager

    private let balanceConverter = BalanceConverter()

    private var destinationAccountAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    private var destinationTokenHeader: ExpressInteractorTokenHeader?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        userWalletId: UserWalletId,
        userToken: SendSourceToken,
        transactionSigner: TangemSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        analyticsLogger: SendAnalyticsLogger,
        sendReceiveTokenBuilder: SendReceiveTokenBuilder,
        sendAlertBuilder: SendAlertBuilder,
        swapManager: SwapManager,
        predefinedValues: PredefinedValues
    ) {
        self.userWalletId = userWalletId
        self.transactionSigner = transactionSigner
        self.feeIncludedCalculator = feeIncludedCalculator
        self.analyticsLogger = analyticsLogger
        self.sendReceiveTokenBuilder = sendReceiveTokenBuilder
        self.sendAlertBuilder = sendAlertBuilder
        self.swapManager = swapManager

        _sendingToken = .init(userToken)
        _receivedToken = .init(.same(userToken))
        _destination = .init(predefinedValues.destination)
        _destinationAdditionalField = .init(predefinedValues.tag)
        _amount = .init(predefinedValues.amount)

        bind()
    }

    deinit {
        AppLogger.debug("SendModel deinit")
    }
}

// MARK: - Validation

private extension SendModel {
    private func bind() {
        Publishers
            .CombineLatest4(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value.transactionAddress },
                _destinationAdditionalField,
                _sendingToken.flatMapLatest { $0.tokenFeeProvidersManager.selectedTokenFeePublisher.compactMap { $0.value } },
            )
            .withWeakCaptureOf(self)
            .asyncMap { manager, args -> Result<BSDKTransaction, Error>? in
                let (amount, destination, additionalField, fee) = args

                switch fee {
                case .loading:
                    return .none
                case .success(let fee):
                    do {
                        let transaction = try await manager.makeTransaction(
                            amountValue: amount,
                            destination: destination,
                            additionalField: additionalField,
                            fee: fee
                        )

                        return .success(transaction)
                    } catch {
                        return .failure(error)
                    }
                case .failure(let error):
                    return .failure(error)
                }
            }
            .withWeakCaptureOf(self)
            .sink { $0._transaction.send($1) }
            .store(in: &bag)

        _amount
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { $0.swapManager.update(amount: $1?.crypto) }
            .store(in: &bag)

        Publishers
            .CombineLatest3(
                _receivedToken.removeDuplicates(),
                _destination.removeDuplicates(),
                _destinationAdditionalField
            )
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { sendModel, args in
                let (receivedToken, destination, additionalField) = args

                sendModel.swapManager.update(
                    userWalletId: sendModel.userWalletId,
                    destination: receivedToken.receiveToken?.tokenItem,
                    address: destination?.value.transactionAddress,
                    additionalField: additionalField,
                    tokenHeader: sendModel.destinationTokenHeader,
                    accountModelAnalyticsProvider: sendModel.destinationAccountAnalyticsProvider
                )
            }
            .store(in: &bag)
    }

    private func makeTransaction(
        amountValue: Decimal,
        destination: String,
        additionalField: SendDestinationAdditionalField,
        fee: Fee
    ) async throws -> BSDKTransaction {
        var amount = makeAmount(decimal: amountValue)
        let includeFee = feeIncludedCalculator.shouldIncludeFee(fee, into: amount)
        _isFeeIncluded.send(includeFee)

        if includeFee {
            amount = makeAmount(decimal: amount.value - fee.amount.value)
        }

        var transactionsParams: TransactionParams?

        if case .filled(_, _, let params) = additionalField {
            transactionsParams = params
        }

        let transaction = try await sourceToken.transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destination,
            params: transactionsParams
        )

        return transaction
    }

    private func makeAmount(decimal: Decimal) -> Amount {
        let tokenItem = _sendingToken.value.tokenItem
        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: decimal)
    }
}

// MARK: - Reset flow

private extension SendModel {
    func resetFlow(
        newReceiveToken: SendReceiveTokenType,
        reset: @escaping () -> Void,
        cancel: @escaping () -> Void = {}
    ) {
        func resetFlowAction() {
            reset()
            externalDestinationUpdater.externalUpdate(address: .init(value: .plain(""), source: .textField))
            router?.resetFlow()
        }

        switch newReceiveToken {
        // If we don't have any destination address
        // We can safely change the token
        case _ where destination == nil:
            reset()

        // If both tokens have the same network
        // it means destination will be valid after change
        // Then we safely change the token
        case .swap(let token) where token.tokenItem.blockchain == receiveToken.tokenItem.blockchain:
            reset()

        case .same(let token) where token.tokenItem.blockchain == receiveToken.tokenItem.blockchain:
            reset()

        case .swap:
            alertPresenter?.showAlert(
                sendAlertBuilder.makeChangeTokenFlowAlert(action: resetFlowAction, cancel: cancel)
            )

        case .same:
            alertPresenter?.showAlert(
                sendAlertBuilder.makeCancelConvertingFlowAlert(action: resetFlowAction, cancel: cancel)
            )
        }
    }
}

// MARK: - Send

private extension SendModel {
    /// 1. First we check the fee is actual
    private func sendIfInformationIsActual() async throws -> TransactionDispatcherResult {
        if informationRelevanceService.isActual {
            return try await sendIfHighPriceImpactWarningChecking()
        }

        let result = try await informationRelevanceService.updateInformation().mapToResult().async()
        switch result {
        case .failure:
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        case .success(.feeWasIncreased):
            throw TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased
        case .success(.ok):
            return try await sendIfHighPriceImpactWarningChecking()
        }
    }

    /// 2. Second we check the high price impact warning
    private func sendIfHighPriceImpactWarningChecking() async throws -> TransactionDispatcherResult {
        if let highPriceImpact = await highPriceImpact, highPriceImpact.isHighPriceImpact {
            let viewModel = HighPriceImpactWarningSheetViewModel(
                highPriceImpact: highPriceImpact,
                tangemIconProvider: CommonTangemIconProvider(signer: transactionSigner)
            )
            router?.openHighPriceImpactWarningSheetViewModel(viewModel: viewModel)

            return try await viewModel.process(send: send)
        }

        return try await send()
    }

    /// 3. Then at the end we start the send actions
    private func send() async throws -> TransactionDispatcherResult {
        do {
            let result = switch receiveToken {
            case .same: try await simpleSend()
            case .swap: try await swapManager.send()
            }
            proceed(result: result)
            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            // rethrows the error forward to display alert
            throw error
        } catch {
            // rethrows the error forward to display alert
            throw error
        }
    }

    private func simpleSend() async throws -> TransactionDispatcherResult {
        guard let transaction = _transaction.value?.value else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let dispatcher = sourceToken.transactionDispatcherProvider.makeTransferTransactionDispatcher()
        let result = try await dispatcher.send(transaction: .transfer(transaction))
        addTokenFromTransactionIfNeeded(transaction)
        return result
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)

        analyticsLogger.logTransactionSent(
            amount: _amount.value,
            additionalField: _destinationAdditionalField.value,
            fee: sourceToken.tokenFeeProvidersManager.selectedTokenFee.option,
            signerType: result.signerType,
            currentProviderHost: result.currentHost,
            tokenFee: sourceToken.tokenFeeProvidersManager.selectedTokenFee
        )
    }

    private func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .demoAlert,
             .userCancelled,
             .loadTransactionInfo,
             .actionNotSupported:
            break
        case .sendTxError(_, let error):
            analyticsLogger.logTransactionRejected(error: error)
        }
    }

    private func addTokenFromTransactionIfNeeded(_ transaction: BSDKTransaction) {
        switch transaction.amount.type.token {
        case .some(let token) where token.metadata.kind == .fungible:
            try? TokenAdder.addToken(defaultAddress: transaction.destinationAddress, token: token)
        default:
            break // NFTs should never be shown in the token list
        }
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
    var destination: SendDestination? { _destination.value }
    var destinationAdditionalField: SendDestinationAdditionalField { _destinationAdditionalField.value }

    var destinationPublisher: AnyPublisher<SendDestination?, Never> {
        _destination.eraseToAnyPublisher()
    }

    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendDestination?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendSourceTokenInput

extension SendModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken { _sendingToken.value }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        _sendingToken.eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        _sendingToken.send(sourceToken)
    }
}

// MARK: - SendSourceTokenAmountInput

extension SendModel: SendSourceTokenAmountInput {
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

extension SendModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendReceiveTokenInput

extension SendModel: SendReceiveTokenInput {
    var isReceiveTokenSelectionAvailable: Bool {
        swapManager.isSwapAvailable
    }

    var receiveToken: SendReceiveTokenType {
        _receivedToken.value
    }

    var receiveTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> {
        _receivedToken.eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendModel: SendReceiveTokenOutput {
    func userDidRequestClearSelection() {
        let newReceiveToken = SendReceiveTokenType.same(_sendingToken.value)
        resetFlow(newReceiveToken: newReceiveToken, reset: { [weak self] in
            self?._receivedToken.send(newReceiveToken)

            self?.analyticsLogger.logAmountStepOpened()
        })
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        let newReceiveToken = SendReceiveTokenType.swap(receiveToken)

        resetFlow(newReceiveToken: newReceiveToken, reset: { [weak self] in
            self?._receivedToken.send(newReceiveToken)
            selected(true)
            self?.analyticsLogger.logAmountStepOpened()
        }, cancel: { [weak self] in
            selected(false)
            self?.analyticsLogger.logAmountStepOpened()
        })
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SendModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        mapToReceiveSendAmount(state: swapManager.state)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        swapManager.statePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToReceiveSendAmount(state: $1) }
            .eraseToAnyPublisher()
    }

    var highPriceImpact: HighPriceImpactCalculator.Result? {
        get async {
            try? await mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: sourceAmount.value,
                receiveTokenAmount: receiveAmount.value,
                provider: swapManager.state.context?.provider
            )
        }
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        Publishers.CombineLatest3(
            sourceAmountPublisher.compactMap { $0.value },
            receiveAmountPublisher.compactMap { $0.value },
            selectedExpressProviderPublisher.compactMap { $0?.provider }
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

    private func mapToReceiveSendAmount(state: SwapManagerState) -> LoadingResult<SendAmount, any Error> {
        switch state {
        case .requiredRefresh(let error, _):
            return .failure(error)
        case .idle, .preloadRestriction, .restriction(_, _, .none), .runtimeRestriction:
            return .failure(SendAmountError.noAmount)
        case .loading:
            return .loading
        case .restriction(_, _, .some(let quote)),
             .permissionRequired(_, _, let quote),
             .readyToSwap(_, _, let quote),
             .previewCEX(_, _, let quote):
            let fiat = receiveToken.tokenItem.currencyId.flatMap { currencyId in
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
        guard let sourceTokenFiatAmount = sourceTokenAmount?.fiat,
              let receiveTokenFiatAmount = receiveTokenAmount?.fiat,
              let provider = provider,
              case .swap(let receiveToken) = receiveToken else {
            return nil
        }

        let impactCalculator = HighPriceImpactCalculator(
            source: sourceToken.tokenItem,
            destination: receiveToken.tokenItem
        )

        let result = try await impactCalculator.isHighPriceImpact(
            provider: provider,
            sourceFiatAmount: sourceTokenFiatAmount,
            destinationFiatAmount: receiveTokenFiatAmount
        )

        return result
    }
}

// MARK: - SendReceiveTokenOutput

extension SendModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChanged(amount: SendAmount?) {
        assertionFailure("Unsupported until fixed rate is available")
    }
}

// MARK: - SendSwapProvidersInput

extension SendModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        get async { await swapManager.providers }
    }

    var expressProvidersPublisher: AnyPublisher<[TangemExpress.ExpressAvailableProvider], Never> {
        swapManager.providersPublisher
    }

    var selectedExpressProvider: ExpressAvailableProvider? {
        swapManager.state.context?.availableProvider
    }

    var selectedExpressProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> {
        swapManager.selectedProviderPublisher
    }
}

// MARK: - SendSwapProvidersOutput

extension SendModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        swapManager.update(provider: provider)
    }
}

// MARK: - SendFeeUpdater

extension SendModel: SendFeeUpdater {
    func updateFees() {
        switch receiveToken {
        case .same: updateFeesForSend()
        case .swap: updateFeesForSwap()
        }
    }

    func updateFeesForSend() {
        guard let amount = _amount.value?.crypto,
              let destination = _destination.value?.value.transactionAddress else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        sourceToken.tokenFeeProvidersManager.updateInputInAllProviders(input: .common(amount: amount, destination: destination))
        sourceToken.tokenFeeProvidersManager.selectedFeeProvider.updateFees()
    }

    func updateFeesForSwap() {
        swapManager.updateFees()
    }
}

// MARK: - SendFeeInput

extension SendModel: SendFeeInput {
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
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { $0.shouldShowFeeSelectorRow(token: $1) }
            .eraseToAnyPublisher()
    }

    private func shouldShowFeeSelectorRow(token: SendReceiveTokenType) -> AnyPublisher<Bool, Never> {
        switch token {
        case .same:
            return .just(output: true)
        case .swap:
            return swapManager.statePublisher
                .filter { !$0.isRefreshRates }
                .map { $0.isFeeRowVisible }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { $0.isReadyToSend(token: $1) }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        sourceToken.tokenFeeProvidersManager
            .selectedFeeProviderPublisher
            .flatMapLatest { $0.statePublisher.map(\.isLoading) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { $0.summaryTransactionData(token: $1) }
            .eraseToAnyPublisher()
    }

    private func isReadyToSend(token: SendReceiveTokenType) -> AnyPublisher<Bool, Never> {
        switch token {
        case .same:
            return _transaction.map { $0?.value != nil }.eraseToAnyPublisher()
        case .swap:
            return swapManager.statePublisher
                // Avoid button disable / non-disable state jumping
                .filter { !$0.isRefreshRates }
                .map { $0.isAvailableToSendTransaction }
                .eraseToAnyPublisher()
        }
    }

    private func summaryTransactionData(token: SendReceiveTokenType) -> AnyPublisher<SendSummaryTransactionData?, Never> {
        switch token {
        case .same:
            return Publishers
                .CombineLatest(_transaction, selectedTokenFeePublisher)
                .withWeakCaptureOf(self)
                .map { model, args -> SendSummaryTransactionData? in
                    let (transaction, selectedFee) = args

                    guard let transaction = transaction?.value else {
                        return nil
                    }

                    return .send(amount: transaction.amount.value, fee: selectedFee)
                }
                .eraseToAnyPublisher()
        case .swap:
            return swapManager
                .statePublisher
                .withWeakCaptureOf(self)
                .flatMap { model, state -> AnyPublisher<SendSummaryTransactionData?, Never> in
                    switch state {
                    case .loading(.refreshRates), .loading(.fee):
                        return Empty().eraseToAnyPublisher()
                    case .idle, .loading(.full), .preloadRestriction,
                         .restriction, .requiredRefresh, .runtimeRestriction:
                        return .just(output: .none)
                    case .permissionRequired(let state, let provider, let quote):
                        let fee = TokenFee(option: .market, tokenItem: state.fee.feeTokenItem, value: .success(state.fee.fee))
                        return .just(
                            output: .swap(
                                amount: quote.fromAmount,
                                fee: fee,
                                provider: provider.provider
                            )
                        )
                    case .previewCEX(_, let context, let quote):
                        return .just(
                            output: .swap(
                                amount: quote.fromAmount,
                                fee: context.tokenFeeProvidersManager.selectedTokenFee,
                                provider: context.provider
                            )
                        )
                    case .readyToSwap(_, let context, let quote):
                        return .just(
                            output: .swap(
                                amount: quote.fromAmount,
                                fee: context.tokenFeeProvidersManager.selectedTokenFee,
                                provider: context.provider
                            )
                        )
                    }
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - SendFinishInput

extension SendModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SendModel: SendBaseInput, SendBaseOutput {
    func stopSwapProvidersAutoUpdateTimer() {
        swapManager.stopTimer()
    }

    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }

    func actualizeInformation() {
        updateFees()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isSending.send(true)
        defer { _isSending.send(false) }

        return try await sendIfInformationIsActual()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> {
        sourceToken.tokenFeeProvidersManager.selectedFeeProvider.feesPublisher
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        sourceToken.tokenFeeProvidersManager.selectedTokenFeePublisher
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }

    var bsdkTransactionPublisher: AnyPublisher<BSDKTransaction?, Never> {
        _transaction.map { $0?.value }.eraseToAnyPublisher()
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transaction.map { $0?.error }.eraseToAnyPublisher()
    }
}

// MARK: - NotificationTapDelegate

extension SendModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            sourceToken.availableBalanceProvider.balanceType.value.flatMap {
                leaveMinimalAmountOnBalance(amountToLeave: amount, balance: $0)
            }
        case .reduceAmountBy(let amount, _, _):
            _amount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh:
            swapManager.update()
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
             .tangemPaySync,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .activate,
             .openCloreMigration:
            assertionFailure("Notification tap not handled")
        }
    }

    private func leaveMinimalAmountOnBalance(amountToLeave amount: Decimal, balance: Decimal) {
        var newAmount = balance - amount

        if let fee = selectedFee?.value.value?.amount, sourceToken.tokenItem.amountType == fee.type {
            // In case when fee can be more that amount
            newAmount = max(0, newAmount - fee.value)
        }

        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: newAmount)
    }

    private func reduceAmountBy(_ amount: Decimal, source: Decimal) {
        var newAmount = source - amount

        if _isFeeIncluded.value, let feeValue = selectedFee?.value.value?.amount.value {
            newAmount = newAmount - feeValue
        }

        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: amount)
    }
}

// MARK: - SendBaseDataBuilderInput

extension SendModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        _amount.value?.crypto.map { makeAmount(decimal: $0) }
    }

    var bsdkFee: BSDKFee? {
        selectedFee?.value.value
    }

    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }
}

// MARK: - SendDestinationAccountOutput

extension SendModel: SendDestinationAccountOutput {
    func setDestinationAccountInfo(
        tokenHeader: ExpressInteractorTokenHeader?,
        analyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        destinationTokenHeader = tokenHeader
        destinationAccountAnalyticsProvider = analyticsProvider
        analyticsLogger.setDestinationAnalyticsProvider(analyticsProvider)
    }
}

// MARK: - FeeSelectorInteractor

extension SendModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        switch receiveToken {
        case .same: sourceToken.tokenFeeProvidersManager
        case .swap: swapManager.tokenFeeProvidersManager
        }
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, receiveToken in
                switch receiveToken {
                case .same: model.sourceTokenPublisher.map(\.tokenFeeProvidersManager).eraseToAnyPublisher()
                case .swap: model.swapManager.tokenFeeProvidersManagerPublisher.eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension SendModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        swapManager.updateFees()
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        switch receiveToken {
        case .same:
            sourceToken.tokenFeeProvidersManager.updateFeeOptionInAllProviders(feeOption: feeOption)
            sourceToken.tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)

        case .swap:
            swapManager.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        }
    }
}

// MARK: - Models

extension SendModel {
    struct PredefinedValues {
        let destination: SendDestination?
        let tag: SendDestinationAdditionalField
        let amount: SendAmount?

        init(
            destination: SendDestination? = nil,
            tag: SendDestinationAdditionalField = .notSupported,
            amount: SendAmount? = nil
        ) {
            self.destination = destination
            self.tag = tag
            self.amount = amount
        }
    }
}
