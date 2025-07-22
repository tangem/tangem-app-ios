//
//  SendWithSwapModel.swift
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

class SendWithSwapModel {
    // MARK: - Data

    private let _sendingToken: CurrentValueSubject<SendSourceToken, Never>
    private let _receivedToken: CurrentValueSubject<SendReceiveTokenType, Never>
    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _selectedFee = CurrentValueSubject<SendFee, Never>(.init(option: .market, value: .loading))
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<Result<BSDKTransaction, Error>?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    var externalAmountUpdater: SendExternalAmountUpdater!
    var sendFeeProvider: SendFeeProvider!
    var informationRelevanceService: InformationRelevanceService!
    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let transactionSigner: TransactionSigner
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let analyticsLogger: SendAnalyticsLogger
    private let sendReceiveTokenBuilder: SendReceiveTokenBuilder
    private let swapManager: SwapManager

    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        userToken: SendSourceToken,
        transactionSigner: TransactionSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        analyticsLogger: SendAnalyticsLogger,
        sendReceiveTokenBuilder: SendReceiveTokenBuilder,
        swapManager: SwapManager,
        predefinedValues: PredefinedValues
    ) {
        self.transactionSigner = transactionSigner
        self.feeIncludedCalculator = feeIncludedCalculator
        self.analyticsLogger = analyticsLogger
        self.sendReceiveTokenBuilder = sendReceiveTokenBuilder
        self.swapManager = swapManager

        _sendingToken = .init(userToken)
        _receivedToken = .init(.same(userToken))
        _destination = .init(predefinedValues.destination)
        _destinationAdditionalField = .init(predefinedValues.tag)
        _amount = .init(predefinedValues.amount)

        bind()
    }
}

// MARK: - Validation

private extension SendWithSwapModel {
    private func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value },
                _selectedFee.compactMap { $0.value.value }
            )
            .withWeakCaptureOf(self)
            .setFailureType(to: Error.self)
            .asyncTryMap { manager, args -> BSDKTransaction in
                let (amount, destination, fee) = args

                return try await manager.makeTransaction(
                    amountValue: amount,
                    destination: destination,
                    fee: fee
                )
            }
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { $0._transaction.send($1) }
            .store(in: &bag)

        Publishers
            .CombineLatest(
                _amount.removeDuplicates(),
                _receivedToken.removeDuplicates()
            )
            .dropFirst()
            .filter { $1.receiveToken != nil }
            .withWeakCaptureOf(self)
            .sink { $0.swapManager.update(amount: $1.0?.crypto) }
            .store(in: &bag)

        Publishers
            .CombineLatest(
                _receivedToken.removeDuplicates(),
                _destination.removeDuplicates()
            )
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, args in
                let (token, destination) = args
                model.swapManager.update(destination: token.receiveToken?.tokenItem, address: destination?.value)
            }
            .store(in: &bag)
    }

    private func makeTransaction(amountValue: Decimal, destination: String, fee: Fee) async throws -> BSDKTransaction {
        var amount = makeAmount(decimal: amountValue)
        let includeFee = feeIncludedCalculator.shouldIncludeFee(fee, into: amount)
        _isFeeIncluded.send(includeFee)

        if includeFee {
            amount = makeAmount(decimal: amount.value - fee.amount.value)
        }

        var transactionsParams: TransactionParams?

        if case .filled(_, _, let params) = _destinationAdditionalField.value {
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

// MARK: - Send

private extension SendWithSwapModel {
    private func sendIfInformationIsActual() async throws -> TransactionDispatcherResult {
        if informationRelevanceService.isActual {
            return try await send()
        }

        let result = try await informationRelevanceService.updateInformation().mapToResult().async()
        switch result {
        case .failure:
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        case .success(.feeWasIncreased):
            throw TransactionDispatcherResult.Error.informationRelevanceServiceFeeWasIncreased
        case .success(.ok):
            return try await send()
        }
    }

    private func send() async throws -> TransactionDispatcherResult {
        switch receiveToken {
        case .same:
            return try await simpleSend()
        case .swap:
            return try await swapManager.send()
        }
    }

    private func simpleSend() async throws -> TransactionDispatcherResult {
        guard let transaction = _transaction.value?.value else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        do {
            let result = try await sourceToken.transactionDispatcher.send(transaction: .transfer(transaction))
            proceed(transaction: transaction, result: result)
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

    private func proceed(transaction: BSDKTransaction, result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        addTokenFromTransactionIfNeeded(transaction)

        analyticsLogger.logTransactionSent(
            amount: _amount.value,
            additionalField: _destinationAdditionalField.value,
            fee: _selectedFee.value,
            signerType: result.signerType
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
        guard let token = transaction.amount.type.token else {
            return
        }

        switch token.metadata.kind {
        case .fungible:
            UserWalletFinder().addToken(
                token,
                in: sourceToken.tokenItem.blockchain,
                for: transaction.destinationAddress
            )
        case .nonFungible:
            break // NFTs should never be shown in the token list
        }
    }
}

// MARK: - SendDestinationInput

extension SendWithSwapModel: SendDestinationInput {
    var destination: SendAddress? { _destination.value }
    var destinationAdditionalField: SendDestinationAdditionalField { _destinationAdditionalField.value }

    var destinationPublisher: AnyPublisher<SendAddress?, Never> {
        _destination.eraseToAnyPublisher()
    }

    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendWithSwapModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendSourceTokenInput

extension SendWithSwapModel: SendSourceTokenInput {
    var sourceToken: SendSourceToken { _sendingToken.value }

    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> {
        _sendingToken.eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendWithSwapModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        _sendingToken.send(sourceToken)
    }
}

// MARK: - SendSourceTokenAmountInput

extension SendWithSwapModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount?, any Error> { .success(_amount.value) }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, any Error>, Never> {
        _amount.map { .success($0) }.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension SendWithSwapModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendReceiveTokenInput

extension SendWithSwapModel: SendReceiveTokenInput {
    var receiveToken: SendReceiveTokenType {
        _receivedToken.value
    }

    var receiveTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> {
        _receivedToken.eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendWithSwapModel: SendReceiveTokenOutput {
    func userDidSelect(receiveToken: SendReceiveToken) {
        _receivedToken.send(.swap(receiveToken))
    }

    func userDidRequestClearSelection() {
        _receivedToken.send(.same(_sendingToken.value))
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SendWithSwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount?, any Error> {
        mapToReceiveSendAmount(state: swapManager.state)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, any Error>, Never> {
        swapManager.statePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToReceiveSendAmount(state: $1) }
            .eraseToAnyPublisher()
    }

    private func mapToReceiveSendAmount(state: SwapManagerState) -> LoadingResult<SendAmount?, any Error> {
        switch state {
        case .restriction(.requiredRefresh(let error), _):
            return .failure(error)
        case .idle, .restriction, .permissionRequired, .readyToSwap:
            return .success(.none)
        case .loading:
            return .loading
        case .previewCEX(_, let quote):
            return .success(.init(type: .typical(crypto: quote.expectAmount, fiat: quote.expectAmount)))
        }
    }
}

// MARK: - SendReceiveTokenOutput

extension SendWithSwapModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChanged(amount: SendAmount?) {
        assertionFailure("Unsupported until fixed rate is available")
    }
}

// MARK: - SendSwapProvidersInput

extension SendWithSwapModel: SendSwapProvidersInput {
    var expressProvidersPublisher: AnyPublisher<[TangemExpress.ExpressAvailableProvider], Never> {
        swapManager.providersPublisher
    }

    var selectedExpressProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> {
        swapManager.selectedProviderPublisher
    }
}

// MARK: - SendSwapProvidersOutput

extension SendWithSwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        swapManager.update(provider: provider)
    }
}

// MARK: - SendFeeInput

extension SendWithSwapModel: SendFeeInput {
    var selectedFee: SendFee {
        _selectedFee.value
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _selectedFee.eraseToAnyPublisher()
    }

    var canChooseFeeOption: AnyPublisher<Bool, Never> {
        sendFeeProvider.feesHasVariants
    }
}

// MARK: - SendFeeProviderInput

extension SendWithSwapModel: SendFeeProviderInput {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        _amount.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension SendWithSwapModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        _selectedFee.send(fee)
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendWithSwapModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .same:
                    return model._transaction.map { $0?.value != nil }.eraseToAnyPublisher()
                case .swap:
                    return model.swapManager.statePublisher.map { state in
                        switch state {
                        // We don't disable main button when rates in refreshing
                        case .loading(.refreshRates), .permissionRequired, .readyToSwap, .previewCEX:
                            return true
                        case .idle, .loading, .restriction:
                            return false
                        }
                    }
                    .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        _selectedFee
            .map { $0.value.isLoading }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        _transaction.map { transaction -> SendSummaryTransactionData? in
            transaction?.value.map {
                .send(amount: $0.amount.value, fee: $0.fee)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension SendWithSwapModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SendWithSwapModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        let refreshRatesPublisher = swapManager.statePublisher.map { state in
            switch state {
            case .loading(.refreshRates): true
            default: false
            }
        }

        return Publishers
            .Merge(_isSending, refreshRatesPublisher)
            .eraseToAnyPublisher()
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

extension SendWithSwapModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeProvider
            .feesPublisher
            .compactMap { $0.value }
            .eraseToAnyPublisher()
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

extension SendWithSwapModel: NotificationTapDelegate {
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
        case .reduceAmountBy(let amount, _):
            _amount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh:
            swapManager.update()
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
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
             .openReferralProgram,
             .unlock,
             .addTokenTrustline,
             .openHotFinishActivation:
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

extension SendWithSwapModel: SendBaseDataBuilderInput {
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

// MARK: - Models

extension SendWithSwapModel {
    typealias PredefinedValues = SendModel.PredefinedValues
}
