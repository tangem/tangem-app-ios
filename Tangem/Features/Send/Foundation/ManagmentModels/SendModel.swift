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

class SendModel {
    // MARK: - Data

    private let _sendingToken: CurrentValueSubject<SendSourceToken, Never>
    private let _receivedToken: CurrentValueSubject<SendReceiveTokenType, Never>
    private let _destination: CurrentValueSubject<SendDestination?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _selectedFee: CurrentValueSubject<SendFee, Never>
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<Result<BSDKTransaction, Error>?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    var externalAmountUpdater: SendAmountExternalUpdater!
    var externalDestinationUpdater: SendDestinationExternalUpdater!
    var sendFeeProvider: SendFeeProvider!
    var informationRelevanceService: InformationRelevanceService!

    weak var router: SendModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let transactionSigner: TangemSigner
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let analyticsLogger: SendAnalyticsLogger
    private let sendReceiveTokenBuilder: SendReceiveTokenBuilder
    private let sendAlertBuilder: SendAlertBuilder
    private let swapManager: SwapManager

    private let balanceConverter = BalanceConverter()

    private var destinationAccountAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        userToken: SendSourceToken,
        transactionSigner: TangemSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        analyticsLogger: SendAnalyticsLogger,
        sendReceiveTokenBuilder: SendReceiveTokenBuilder,
        sendAlertBuilder: SendAlertBuilder,
        swapManager: SwapManager,
        predefinedValues: PredefinedValues
    ) {
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
        _selectedFee = .init(.init(option: .market, tokenItem: _sendingToken.value.feeTokenItem, value: .loading))

        bind()
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
                _selectedFee.map { $0.value }
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

        _selectedFee
            .map { $0.option }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            // Filter that SwapManager has different option
            .filter { $0.mapToSendFee(state: $0.swapManager.state).option != $1 }
            .sink { $0.swapManager.update(feeOption: $1) }
            .store(in: &bag)

        Publishers
            .CombineLatest(
                _receivedToken.removeDuplicates(),
                _destination.removeDuplicates()
            )
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink {
                $0.swapManager.update(
                    destination: $1.0.receiveToken?.tokenItem,
                    address: $1.1?.value.transactionAddress,
                    accountModelAnalyticsProvider: $0.destinationAccountAnalyticsProvider
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

        let result = try await sourceToken.transactionDispatcher.send(transaction: .transfer(transaction))
        addTokenFromTransactionIfNeeded(transaction)
        return result
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)

        analyticsLogger.logTransactionSent(
            amount: _amount.value,
            additionalField: _destinationAdditionalField.value,
            fee: _selectedFee.value,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
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
                provider: swapManager.selectedProvider?.provider
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
        case .restriction(.requiredRefresh(let error), _):
            return .failure(error)
        case .idle, .restriction:
            return .failure(SendAmountError.noAmount)
        case .loading:
            return .loading
        case .permissionRequired(_, let quote), .readyToSwap(_, let quote), .previewCEX(_, let quote):
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
        get async { await swapManager.selectedProvider }
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

// MARK: - SendFeeInput

extension SendModel: SendFeeInput {
    var selectedFee: SendFee {
        switch receiveToken {
        case .same: _selectedFee.value
        case .swap: mapToSendFee(state: swapManager.state)
        }
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, receiveToken in
                switch receiveToken {
                case .same:
                    return model._selectedFee.eraseToAnyPublisher()
                case .swap:
                    return model.swapManager.statePublisher
                        .filter { !$0.isRefreshRates }
                        .map { model.mapToSendFee(state: $0) }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    var canChooseFeeOption: AnyPublisher<Bool, Never> {
        sendFeeProvider.feesHasVariants
    }

    private func mapToSendFee(state: SwapManagerState) -> SendFee {
        switch state {
        case .loading:
            return .init(option: state.fees.selected, tokenItem: sourceToken.feeTokenItem, value: .loading)
        case .restriction(.requiredRefresh(let occurredError), _):
            return .init(option: state.fees.selected, tokenItem: sourceToken.feeTokenItem, value: .failure(occurredError))
        case let state:
            let fee = Result { try state.fees.selectedFee() }
            return .init(option: state.fees.selected, tokenItem: sourceToken.feeTokenItem, value: .result(fee))
        }
    }
}

// MARK: - SendFeeProviderInput

extension SendModel: SendFeeProviderInput {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        _amount.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0?.value.transactionAddress }.eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension SendModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        _selectedFee.send(fee)
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
        _selectedFee
            .map { $0.value.isLoading }
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
                .map { state in
                    switch state {
                    case .loading, .readyToSwap, .previewCEX:
                        return true
                    case .idle, .restriction, .permissionRequired:
                        return false
                    }
                }
                .eraseToAnyPublisher()
        }
    }

    private func summaryTransactionData(token: SendReceiveTokenType) -> AnyPublisher<SendSummaryTransactionData?, Never> {
        switch token {
        case .same:
            return _transaction
                .withWeakCaptureOf(self)
                .map { model, transaction -> SendSummaryTransactionData? in
                    guard let transaction = transaction?.value else {
                        return nil
                    }

                    return .send(amount: transaction.amount.value, fee: transaction.fee)
                }
                .eraseToAnyPublisher()
        case .swap:
            return Publishers.CombineLatest(
                swapManager.statePublisher,
                swapManager.selectedProviderPublisher
            )
            .withWeakCaptureOf(self)
            .flatMap {
                model,
                    args -> AnyPublisher<SendSummaryTransactionData?, Never> in
                let (state, selectedProvider) = args
                switch state {
                case .loading(.refreshRates), .loading(.fee):
                    return Empty().eraseToAnyPublisher()
                case .idle, .loading(.full):
                    return .just(output: .none)
                case let state:
                    guard let provider = selectedProvider?.provider else {
                        return .just(output: .none)
                    }

                    let amount = state.quote?.fromAmount
                    let fee = try? state.fees.selectedFee()

                    return .just(
                        output: .swap(amount: amount, fee: fee, provider: provider)
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
    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }

    func actualizeInformation() {
        sendFeeProvider.updateFees()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isSending.send(true)
        defer { _isSending.send(false) }

        return try await sendIfInformationIsActual()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeProvider.feesPublisher.eraseToAnyPublisher()
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
            sendFeeProvider.updateFees()
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
             .tangemPaySync,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .activate:
            assertionFailure("Notification tap not handled")
        }
    }

    private func leaveMinimalAmountOnBalance(amountToLeave amount: Decimal, balance: Decimal) {
        var newAmount = balance - amount

        if let fee = selectedFee.value.value?.amount, sourceToken.tokenItem.amountType == fee.type {
            // In case when fee can be more that amount
            newAmount = max(0, newAmount - fee.value)
        }

        // Amount will be changed automatically via SendAmountOutput
        externalAmountUpdater.externalUpdate(amount: newAmount)
    }

    private func reduceAmountBy(_ amount: Decimal, source: Decimal) {
        var newAmount = source - amount

        if _isFeeIncluded.value, let feeValue = selectedFee.value.value?.amount.value {
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

    var bsdkFee: BlockchainSdk.Fee? {
        selectedFee.value.value
    }

    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }
}

// MARK: - SendDestinationAccountOutput

extension SendModel: SendDestinationAccountOutput {
    func setDestinationAccountAnalyticsProvider(_ provider: (any AccountModelAnalyticsProviding)?) {
        destinationAccountAnalyticsProvider = provider
        analyticsLogger.setDestinationAnalyticsProvider(provider)
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
