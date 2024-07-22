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

    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)

    // MARK: - Dependencies

    var sendAmountInteractor: SendAmountInteractor!
    var sendFeeInteractor: SendFeeInteractor!
    var informationRelevanceService: InformationRelevanceService!
    weak var router: SendModelRoutable?

    // MARK: - Private stuff

    private let walletModel: WalletModel
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let transactionSigner: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    private let source: PredefinedValues.Source
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        walletModel: WalletModel,
        sendTransactionDispatcher: SendTransactionDispatcher,
        transactionCreator: TransactionCreator,
        transactionSigner: TransactionSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        predefinedValues: PredefinedValues
    ) {
        self.walletModel = walletModel
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.feeIncludedCalculator = feeIncludedCalculator
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder

        source = predefinedValues.source
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

        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destination
        )

        return transaction
    }

    private func makeAmount(decimal: Decimal) -> Amount {
        Amount(
            with: walletModel.tokenItem.blockchain,
            type: walletModel.tokenItem.amountType,
            value: decimal
        )
    }
}

// MARK: - Send

private extension SendModel {
    private func sendIfInformationIsActual() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        if informationRelevanceService.isActual {
            return send()
        }

        return informationRelevanceService
            .updateInformation()
            .mapToResult()
            .withWeakCaptureOf(self)
            .flatMap { manager, result -> AnyPublisher<SendTransactionDispatcherResult, Never> in
                switch result {
                case .failure:
                    return .just(output: .informationRelevanceServiceError)
                case .success(.feeWasIncreased):
                    return .just(output: .informationRelevanceServiceFeeWasIncreased)
                case .success(.ok):
                    return manager.send()
                }
            }
            .eraseToAnyPublisher()
    }

    private func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard let transaction = _transaction.value?.value else {
            return .just(output: .transactionNotFound)
        }

        return sendTransactionDispatcher
            .send(transaction: transaction)
            .withWeakCaptureOf(self)
            .compactMap { sender, result in
                sender.proceed(transaction: transaction, result: result)
                return result
            }
            .eraseToAnyPublisher()
    }

    private func proceed(transaction: BSDKTransaction, result: SendTransactionDispatcherResult) {
        switch result {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .demoAlert,
             .userCancelled:
            break
        case .sendTxError:
            Analytics.log(event: .sendErrorTransactionRejected, params: [
                .token: walletModel.tokenItem.currencySymbol,
            ])
        case .success:
            _transactionTime.send(Date())
            logTransactionAnalytics()

            transaction.amount.type.token.map { token in
                UserWalletFinder().addToken(
                    token,
                    in: walletModel.tokenItem.blockchain,
                    for: transaction.destinationAddress
                )
            }
        }
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
    var destinationPublisher: AnyPublisher<SendAddress, Never> {
        _destination
            .compactMap { $0 }
            .eraseToAnyPublisher()
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

    var cryptoAmountPublisher: AnyPublisher<BlockchainSdk.Amount, Never> {
        _amount
            .withWeakCaptureOf(self)
            .compactMap { model, amount in
                amount?.crypto.flatMap { model.makeAmount(decimal: $0) }
            }
            .eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        _destination.map { $0?.value }.eraseToAnyPublisher()
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
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> {
        _transaction.map { $0?.value }.eraseToAnyPublisher()
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
    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }

    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionDispatcher.isSending
    }

    func sendTransaction() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        sendIfInformationIsActual()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeInteractor.feesPublisher
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
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
            sendFeeInteractor.updateFees()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        case .leaveAmount(let amount, _):
            walletModel.balanceValue.map { reduceAmountBy(amount, source: $0) }
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
             .stake,
             .openLink,
             .swap,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support:
            assertionFailure("Notification tap not handled")
        }
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

// MARK: - Analytics

private extension SendModel {
    func logTransactionAnalytics() {
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)

        Analytics.log(event: .transactionSent, params: [
            .source: source.analyticsValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        switch amount?.type {
        case .none:
            break
        case .typical:
            Analytics.log(.sendSelectedCurrency, params: [.commonType: .token])

        case .alternative:
            Analytics.log(.sendSelectedCurrency, params: [.commonType: .selectedCurrencyApp])
        }
    }

    func additionalFieldAnalyticsParameter() -> Analytics.ParameterValue {
        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        switch _destinationAdditionalField.value {
        case .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }
    }
}

// MARK: - Models

extension SendModel {
    struct PredefinedValues {
        let source: Source

        let destination: SendAddress?
        let tag: SendDestinationAdditionalField
        let amount: SendAmount?

        enum Source {
            case send
            case sell

            var analyticsValue: Analytics.ParameterValue {
                switch self {
                case .send: .transactionSourceSend
                case .sell: .transactionSourceSell
                }
            }
        }
    }
}
