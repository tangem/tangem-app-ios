//
//  TransferModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemFoundation

/// A simplified version of SendModel that handles only simple send transactions without swap/exchange functionality.
final class TransferModel {
    // MARK: - Data

    private let _sourceToken: SendTransferableToken
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
    private let sendAlertBuilder: SendAlertBuilder

    private let balanceConverter = BalanceConverter()

    private var destinationAccountAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    private var destinationTokenHeader: ExpressInteractorTokenHeader?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        userWalletId: UserWalletId,
        userToken: SendTransferableToken,
        transactionSigner: TangemSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        analyticsLogger: SendAnalyticsLogger,
        sendAlertBuilder: SendAlertBuilder,
        predefinedValues: PredefinedValues
    ) {
        self.userWalletId = userWalletId
        self.transactionSigner = transactionSigner
        self.feeIncludedCalculator = feeIncludedCalculator
        self.analyticsLogger = analyticsLogger
        self.sendAlertBuilder = sendAlertBuilder

        _sourceToken = userToken
        _destination = .init(predefinedValues.destination)
        _destinationAdditionalField = .init(predefinedValues.tag)
        _amount = .init(predefinedValues.amount)

        bind()
    }

    deinit {
        AppLogger.debug("TransferModel deinit")
    }
}

// MARK: - Validation

private extension TransferModel {
    private func bind() {
        Publishers
            .CombineLatest4(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value.transactionAddress },
                _destinationAdditionalField,
                _sourceToken.tokenFeeProvidersManager.selectedTokenFeePublisher.compactMap { $0.value }
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

        let transaction = try await _sourceToken.transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destination,
            params: transactionsParams
        )

        return transaction
    }

    private func makeAmount(decimal: Decimal) -> Amount {
        let tokenItem = _sourceToken.tokenItem
        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: decimal)
    }
}

// MARK: - Send

private extension TransferModel {
    /// 1. First we check the fee is actual
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

    /// 2. Execute the send transaction
    private func send() async throws -> TransactionDispatcherResult {
        do {
            let result = try await simpleSend()
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

        let dispatcher = _sourceToken.transactionDispatcherProvider.makeTransferTransactionDispatcher()
        let result = try await dispatcher.send(transaction: .transfer(transaction))
        addTokenFromTransactionIfNeeded(transaction)
        return result
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        _transactionURL.send(result.url)

        let tokenFeeProvidersManager = _sourceToken.tokenFeeProvidersManager
        analyticsLogger.logTransactionSent(
            amount: _amount.value,
            additionalField: _destinationAdditionalField.value,
            fee: tokenFeeProvidersManager.selectedTokenFee.option,
            signerType: result.signerType,
            currentProviderHost: result.currentHost,
            tokenFee: tokenFeeProvidersManager.selectedTokenFee
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

extension TransferModel: SendDestinationInput {
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

extension TransferModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendDestination?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendSourceTokenInput

extension TransferModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        .success(_sourceToken as SendSourceToken)
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        Just(sourceToken).eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenOutput

extension TransferModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        assertionFailure("TransferModel doesn't support SourceToken updating")
    }
}

// MARK: - SendSourceTokenAmountInput

extension TransferModel: SendSourceTokenAmountInput {
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

extension TransferModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendFeeUpdater

extension TransferModel: SendFeeUpdater {
    func updateFees() {
        guard let amount = _amount.value?.crypto,
              let destination = _destination.value?.value.transactionAddress else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        _sourceToken.tokenFeeProvidersManager.update(input: .common(amount: amount, destination: destination))
        _sourceToken.tokenFeeProvidersManager.selectedFeeProvider.updateFees()
    }
}

// MARK: - SendFeeInput

extension TransferModel: SendFeeInput {
    var selectedFee: TokenFee? {
        _sourceToken.tokenFeeProvidersManager.selectedTokenFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        _sourceToken.tokenFeeProvidersManager.selectedTokenFeePublisher
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        _sourceToken.tokenFeeProvidersManager.supportFeeSelectionPublisher
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        // Always show fee selector for simple sends
        Just(true).eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension TransferModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _transaction.map { $0?.value != nil }.eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        _sourceToken.tokenFeeProvidersManager
            .selectedFeeProviderPublisher
            .flatMapLatest { $0.statePublisher.map(\.isLoading) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers
            .CombineLatest(_transaction, selectedFeePublisher)
            .map { transaction, selectedFee -> SendSummaryTransactionData? in
                guard let transaction = transaction?.value else {
                    return nil
                }

                return .send(amount: transaction.amount.value, fee: selectedFee)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension TransferModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension TransferModel: SendBaseInput, SendBaseOutput {
    func stopSwapProvidersAutoUpdateTimer() {
        // No-op: swap functionality not supported
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

extension TransferModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> {
        _sourceToken.tokenFeeProvidersManager.selectedFeeProvider.feesPublisher
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        _sourceToken.tokenFeeProvidersManager.selectedTokenFeePublisher
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

extension TransferModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            _sourceToken.availableBalanceProvider.balanceType.value.flatMap {
                leaveMinimalAmountOnBalance(amountToLeave: amount, balance: $0)
            }
        case .reduceAmountBy(let amount, _, _):
            _amount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .refresh,
             .givePermission:
            // These actions are swap-related and not supported in TransferModel
            assertionFailure("Swap-related notification tap not supported in TransferModel")
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

        if let fee = selectedFee?.value.value?.amount, _sourceToken.tokenItem.amountType == fee.type {
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

extension TransferModel: SendBaseDataBuilderInput {
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

extension TransferModel: SendDestinationAccountOutput {
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

extension TransferModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        _sourceToken.tokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        .just(output: _sourceToken.tokenFeeProvidersManager)
    }
}

// MARK: - FeeSelectorOutput

extension TransferModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        // Refresh fees after fee selection is dismissed
        updateFees()
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        _sourceToken.tokenFeeProvidersManager.update(feeOption: feeOption)
        _sourceToken.tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
    }
}

// MARK: - Models

extension TransferModel {
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
