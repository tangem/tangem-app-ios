//
//  SendModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendModelRoutable: AnyObject {
    func openNetworkCurrency()
}

class SendModel {
    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _selectedFee = CurrentValueSubject<SendFee, Never>(.init(option: .market, value: .loading))
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<Result<BSDKTransaction, Error>?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    var sendAmountInteractor: SendAmountInteractor!
    var sendFeeProvider: SendFeeProvider!
    var informationRelevanceService: InformationRelevanceService!
    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let tokenItem: TokenItem
    private let balanceProvider: TokenBalanceProvider
    private let transactionDispatcher: TransactionDispatcher
    private let transactionSigner: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let analyticsLogger: SendAnalyticsLogger

    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        tokenItem: TokenItem,
        balanceProvider: TokenBalanceProvider,
        transactionDispatcher: TransactionDispatcher,
        transactionCreator: TransactionCreator,
        transactionSigner: TransactionSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        analyticsLogger: SendAnalyticsLogger,
        predefinedValues: PredefinedValues
    ) {
        self.tokenItem = tokenItem
        self.balanceProvider = balanceProvider
        self.transactionDispatcher = transactionDispatcher
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.feeIncludedCalculator = feeIncludedCalculator
        self.analyticsLogger = analyticsLogger

        _destination = .init(predefinedValues.destination)
        _destinationAdditionalField = .init(predefinedValues.tag)
        _amount = .init(predefinedValues.amount)

        bind()
    }
}

// MARK: - Validation

private extension SendModel {
    private func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value },
                _selectedFee.compactMap { $0.value.value }
            )
            .withWeakCaptureOf(self)
            .asyncMap { manager, args async -> Result<BSDKTransaction, Error> in
                do {
                    let transaction = try await manager.makeTransaction(
                        amountValue: args.0,
                        destination: args.1,
                        fee: args.2
                    )
                    return .success(transaction)
                } catch {
                    return .failure(error)
                }
            }
            .sink { [weak self] result in
                self?._transaction.send(result)
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

        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destination,
            params: transactionsParams
        )

        return transaction
    }

    private func makeAmount(decimal: Decimal) -> Amount {
        Amount(
            with: tokenItem.blockchain,
            type: tokenItem.amountType,
            value: decimal
        )
    }
}

// MARK: - Send

private extension SendModel {
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
        guard let transaction = _transaction.value?.value else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        do {
            let result = try await transactionDispatcher.send(transaction: .transfer(transaction))
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
        analyticsLogger.logTransactionSent(
            amount: _amount.value,
            additionalField: _destinationAdditionalField.value,
            fee: _selectedFee.value,
            signerType: result.signerType
        )
        addTokenFromTransactionIfNeeded(transaction)
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
                in: tokenItem.blockchain,
                for: transaction.destinationAddress
            )
        case .nonFungible:
            break // NFTs should never be shown in the token list
        }
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
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

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendAmountInput

extension SendModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension SendModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendFeeInput

extension SendModel: SendFeeInput {
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

extension SendModel: SendFeeProviderInput {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        _amount.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0?.value }.eraseToAnyPublisher()
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
        _transaction.map { $0?.value != nil }.eraseToAnyPublisher()
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

extension SendModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
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

extension SendModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            sendFeeProvider.updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            balanceProvider.balanceType.value.flatMap {
                leaveMinimalAmountOnBalance(amountToLeave: amount, balance: $0)
            }
        case .reduceAmountBy(let amount, _):
            _amount.value?.crypto.flatMap { reduceAmountBy(amount, source: $0) }
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
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
             .openHotFinishActivation,
             .unlock:
            assertionFailure("Notification tap not handled")
        }
    }

    private func leaveMinimalAmountOnBalance(amountToLeave amount: Decimal, balance: Decimal) {
        var newAmount = balance - amount

        if let fee = selectedFee.value.value?.amount, tokenItem.amountType == fee.type {
            // In case when fee can be more that amount
            newAmount = max(0, newAmount - fee.value)
        }

        // Amount will be changed automatically via SendAmountOutput
        sendAmountInteractor.externalUpdate(amount: newAmount)
    }

    private func reduceAmountBy(_ amount: Decimal, source: Decimal) {
        var newAmount = source - amount
        if _isFeeIncluded.value, let feeValue = selectedFee.value.value?.amount.value {
            newAmount = newAmount - feeValue
        }

        // Amount will be changed automatically via SendAmountOutput
        sendAmountInteractor.externalUpdate(amount: newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        // Amount will be changed automatically via SendAmountOutput
        sendAmountInteractor.externalUpdate(amount: amount)
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

// MARK: - Models

extension SendModel {
    struct PredefinedValues {
        let destination: SendAddress?
        let tag: SendDestinationAdditionalField
        let amount: SendAmount?
    }
}
