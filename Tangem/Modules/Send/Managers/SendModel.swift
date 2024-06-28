//
//  SendModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendModelUIDelegate: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

class SendModel {
    typealias BSDKTransaction = BlockchainSdk.Transaction

    // MARK: - Delegate

    weak var delegate: SendModelUIDelegate?

    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<DestinationAdditionalFieldType, Never>
    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedFee = CurrentValueSubject<SendFee?, Never>(nil)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<BSDKTransaction?, Never>(nil)
    private let _transactionError = CurrentValueSubject<Error?, Never>(nil)
    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)

    // MARK: - Private stuff

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let sendTransactionSender: SendTransactionSender
    private let transactionSigner: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let sendAmountInteractor: SendAmountInteractor
    private let sendFeeInteractor: SendFeeInteractor
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let informationRelevanceService: InformationRelevanceService
    private let emailDataProvider: EmailDataProvider
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private let sendType: SendType
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    var currencySymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    // MARK: - Public interface

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        sendTransactionSender: SendTransactionSender,
        transactionCreator: TransactionCreator,
        transactionSigner: TransactionSigner,
        sendAmountInteractor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor,
        feeIncludedCalculator: FeeIncludedCalculator,
        informationRelevanceService: InformationRelevanceService,
        emailDataProvider: EmailDataProvider,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendType: SendType,
        coordinator: SendRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.sendTransactionSender = sendTransactionSender
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.sendFeeInteractor = sendFeeInteractor
        self.feeIncludedCalculator = feeIncludedCalculator
        self.sendAmountInteractor = sendAmountInteractor
        self.informationRelevanceService = informationRelevanceService
        self.emailDataProvider = emailDataProvider
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendType = sendType
        self.coordinator = coordinator

        let destination = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        _destination = .init(destination)

        let fields = SendAdditionalFields.fields(for: walletModel.blockchainNetwork.blockchain)
        let type = fields.map { DestinationAdditionalFieldType.empty(type: $0) } ?? .notSupported
        _destinationAdditionalField = .init(type)

        bind()

        // Update the fees in case we have all prerequisites specified
        if sendType.predefinedAmount != nil, sendType.predefinedDestination != nil {
            sendFeeInteractor.updateFees()
        }
    }

    private func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value },
                _selectedFee.compactMap { $0?.value.value }
            )
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { manager, args async throws -> BSDKTransaction in
                try await manager.makeTransaction(amountValue: args.0, destination: args.1, fee: args.2)
            }
            .mapToResult()
            .sink { [weak self] result in
                switch result {
                case .failure(let error):
                    self?._transactionError.send(error)
                case .success(let transaction):
                    self?._transaction.send(transaction)
                }
            }
            .store(in: &bag)

        guard let withdrawalValidator = walletModel.withdrawalNotificationProvider else {
            return
        }

        _transaction
            .compactMap { $0 }
            .map { transaction in
                return withdrawalValidator.withdrawalNotification(amount: transaction.amount, fee: transaction.fee.amount)
            }
            .sink { [weak self] in
                self?._withdrawalNotification.send($0)
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
        Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: decimal)
    }

    private func openMail(transaction: Transaction, error: SendTxError) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: _isFeeIncluded.value,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }
}

// MARK: - Send

private extension SendModel {
    private func sendIfInformationIsActual() -> AnyPublisher<SendTransactionSentResult, Never> {
        if informationRelevanceService.isActual {
            return send()
        }

        return informationRelevanceService
            .updateInformation()
            .mapToResult()
            .withWeakCaptureOf(self)
            .flatMap { manager, result -> AnyPublisher<SendTransactionSentResult, Never> in
                switch result {
                case .failure:
                    return Deferred {
                        Future { promise in
                            manager.delegate?.showAlert(SendAlertBuilder.makeFeeRetryAlert {
                                promise(.success(()))
                            })
                        }
                    }
                    .withWeakCaptureOf(self)
                    .flatMap { manager, _ in
                        manager.send()
                    }
                    .eraseToAnyPublisher()

                case .success(.feeWasIncreased):
                    manager.delegate?.showAlert(
                        AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
                    )

                    return Empty().eraseToAnyPublisher()
                case .success(.ok):
                    return manager.send()
                }
            }
            .eraseToAnyPublisher()
    }

    private func send() -> AnyPublisher<SendTransactionSentResult, Never> {
        guard let transaction = _transaction.value else {
            return Empty().eraseToAnyPublisher()
        }

        return sendTransactionSender
            .send(transaction: transaction)
            .mapToResult()
            .withWeakCaptureOf(self)
            .compactMap { sender, result in
                return sender.proceed(transaction: transaction, result: result)
            }
            .eraseToAnyPublisher()
    }

    private func proceed(transaction: BSDKTransaction, result: Result<SendTransactionSentResult, SendTxError>) -> SendTransactionSentResult? {
        switch result {
        case .success(let result):
            proceed(transaction: transaction, result: result)
            return result
        case .failure(let error):
            proceed(transaction: transaction, error: error)
            return nil
        }
    }

    private func proceed(transaction: BSDKTransaction, result: SendTransactionSentResult) {
        if walletModel.isDemo {
            let alert = AlertBuilder.makeAlert(
                title: "",
                message: Localization.alertDemoFeatureDisabled,
                primaryButton: .default(.init(Localization.commonOk)) { [weak self] in
                    self?.coordinator?.dismiss()
                }
            )

            delegate?.showAlert(alert)
        } else {
            logTransactionAnalytics()
        }

        if let token = transaction.amount.type.token {
            UserWalletFinder().addToken(
                token,
                in: walletModel.blockchainNetwork.blockchain,
                for: transaction.destinationAddress
            )
        }
    }

    private func proceed(transaction: BSDKTransaction, error: SendTxError) {
        Analytics.log(event: .sendErrorTransactionRejected, params: [
            .token: walletModel.tokenItem.currencySymbol,
        ])

        switch error.error {
        case WalletError.noAccount(_, let amount):
            let amountFormatted = Amount(
                with: walletModel.blockchainNetwork.blockchain,
                type: walletModel.amountType,
                value: amount
            ).string()

            // "Use TransactionValidator async validate to get this warning before send tx"
            let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
            let message = Localization.sendNotificationInvalidReserveAmountText
            delegate?.showAlert(AlertBinder(title: title, message: message))
        default:
            let errorCode: String
            let reason = String(error.localizedDescription.dropTrailingPeriod)
            if let errorCodeProviding = error as? ErrorCodeProviding {
                errorCode = "\(errorCodeProviding.errorCode)"
            } else {
                errorCode = "-"
            }

            let sendError = SendError(
                title: Localization.sendAlertTransactionFailedTitle,
                message: Localization.sendAlertTransactionFailedText(reason, errorCode),
                error: error,
                openMailAction: { [weak self] error in
                    self?.openMail(transaction: transaction, error: error)
                }
            )

            delegate?.showAlert(sendError.alertBinder)
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

    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendAmountInput

extension SendModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.dropFirst().eraseToAnyPublisher()
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
    var selectedFee: SendFee? {
        _selectedFee.value
    }

    var selectedFeePublisher: AnyPublisher<SendFee?, Never> {
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
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> {
        _transaction.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension SendModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SendModel: SendBaseInput, SendBaseOutput {
    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    func sendTransaction() -> AnyPublisher<SendTransactionSentResult, Never> {
        sendIfInformationIsActual()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    // TODO: Refactoring in https://tangem.atlassian.net/browse/IOS-7196
    var selectedSendFeePublisher: AnyPublisher<SendFee?, Never> {
        selectedFeePublisher
    }

    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeInteractor.feesPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<(any Error)?, Never> {
        .just(output: nil) // TODO: Check it
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionError.eraseToAnyPublisher()
    }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> {
        _withdrawalNotification.eraseToAnyPublisher()
    }
}

// MARK: - NotificationTapDelegate

extension SendModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            sendFeeInteractor.updateFees()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .leaveAmount(let amount, _):
            reduceAmountBy(amount, from: walletModel.balanceValue)
        case .reduceAmountBy(let amount, _):
            reduceAmountBy(amount, from: self.amount?.crypto)
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .goToProvider,
             .addHederaTokenAssociation,
             .bookNow,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview:
            assertionFailure("Notification tap not handled")
        }
    }

    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }

    private func reduceAmountBy(_ amount: Decimal, from source: Decimal?) {
        guard let source else {
            assertionFailure("WHY")
            return
        }

        var newAmount = source - amount
        if _isFeeIncluded.value, let feeValue = selectedFee?.value.value?.amount.value {
            newAmount = newAmount - feeValue
        }

        _ = sendAmountInteractor.update(amount: newAmount)
//        self._amount.send(SendAmount(type: .typical(crypto: <#T##Decimal?#>, fiat: <#T##Decimal?#>)))
//        sendAmountViewModel.setExternalAmount(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        _ = sendAmountInteractor.update(amount: amount)
//        sendAmountViewModel.setExternalAmount(amount)
    }
}

// MARK: - Analytics

private extension SendModel {
    func logTransactionAnalytics() {
        let sourceValue: Analytics.ParameterValue
        switch sendType {
        case .send:
            sourceValue = .transactionSourceSend
        case .sell:
            sourceValue = .transactionSourceSell
        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee?.option)

        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        if let amount {
            Analytics.log(.sendSelectedCurrency, params: [
                .commonType: amount.type.analyticParameter,
            ])
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

extension SendAmount.SendAmountType {
    var analyticParameter: Analytics.ParameterValue {
        switch self {
        case .typical: .token
        case .alternative: .selectedCurrencyApp
        }
    }
}
