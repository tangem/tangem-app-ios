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
import BigInt
import BlockchainSdk

class SendModel {
    var amountValid: AnyPublisher<Bool, Never> {
        amount
            .map {
                $0 != nil
            }
            .eraseToAnyPublisher()
    }

    var destinationValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(destination, destinationAdditionalFieldError)
            .map {
                $0 != nil && $1 == nil
            }
            .eraseToAnyPublisher()
    }

    var feeValid: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    var sendError: AnyPublisher<Error?, Never> {
        _sendError.eraseToAnyPublisher()
    }

    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }

    var transactionFinished: AnyPublisher<Bool, Never> {
        _transactionTime
            .map {
                $0 != nil
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Data

    private let amount = CurrentValueSubject<Amount?, Never>(nil)
    private let destination = CurrentValueSubject<String?, Never>(nil)
    private let fee = CurrentValueSubject<Fee?, Never>(nil)

    private var transactionParameters: TransactionParams?
    private let _transactionCreationError = CurrentValueSubject<Error?, Never>(nil)
    private let _withdrawalSuggestion = CurrentValueSubject<WithdrawalSuggestion?, Never>(nil)
    private let transaction = CurrentValueSubject<BlockchainSdk.Transaction?, Never>(nil)

    // MARK: - Raw data

    private var _amount = CurrentValueSubject<Amount?, Never>(nil)
    private var _isValidatingDestination = CurrentValueSubject<Bool, Never>(false)
    private var _destinationText = CurrentValueSubject<String, Never>("")
    private var _destinationAdditionalFieldText = CurrentValueSubject<String, Never>("")
    private var _additionalFieldEmbeddedInAddress = CurrentValueSubject<Bool, Never>(false)
    private var _selectedFeeOption = CurrentValueSubject<FeeOption, Never>(.market)
    private var _feeValues = CurrentValueSubject<[FeeOption: LoadingValue<Fee>], Never>([:])
    private var _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _transactionTime = CurrentValueSubject<Date?, Never>(nil)
    private let _transactionURL = CurrentValueSubject<URL?, Never>(nil)

    private let _sendError = PassthroughSubject<Error?, Never>()

    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let _customFeeGasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let _customFeeGasLimit = CurrentValueSubject<BigUInt?, Never>(nil)

    // MARK: - Errors (raw implementation)

    private let _amountError = CurrentValueSubject<Error?, Never>(nil)
    private let _destinationError = CurrentValueSubject<Error?, Never>(nil)
    private let _destinationAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)
    private let _feeError = CurrentValueSubject<Error?, Never>(nil)

    // MARK: - Private stuff

    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let addressService: SendAddressService
    private let sendType: SendType
    private var destinationResolutionRequest: Task<Void, Error>?
    private var didSetCustomFee = false
    private var feeUpdatePublisher: AnyPublisher<FeeUpdateResult, Error>?
    private var feeUpdateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(walletModel: WalletModel, transactionSigner: TransactionSigner, addressService: SendAddressService, sendType: SendType) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.sendType = sendType
        self.addressService = addressService

        if let amount = sendType.predefinedAmount {
            #warning("TODO")
            setAmount(amount)
        }

        if let destination = sendType.predefinedDestination {
            setDestination(destination)
        }

        validateDestination()
        validateDestinationAdditionalField()
        bind()
    }

    func useMaxAmount() {
        let amountType = walletModel.amountType
        if let amount = walletModel.wallet.amounts[amountType] {
            setAmount(amount)
            if walletModel.tokenItem == walletModel.feeTokenItem {
                #warning("[REDACTED_TODO_COMMENT]")
                didChangeFeeInclusion(true)
            }
        }
    }

    func currentTransaction() -> BlockchainSdk.Transaction? {
        transaction.value
    }

    @discardableResult
    func updateFees() -> AnyPublisher<FeeUpdateResult, Error> {
        updateFees(amount: amount.value, destination: destination.value)
    }

    func send() {
        guard var transaction = transaction.value else {
            AppLog.shared.debug("Transaction object hasn't been created")
            return
        }

        #warning("[REDACTED_TODO_COMMENT]")
        #warning("[REDACTED_TODO_COMMENT]")

        transaction.params = transactionParameters

        _isSending.send(true)
        walletModel.send(transaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }

                _isSending.send(false)

                if case .failure(let error) = completion,
                   !error.toTangemSdkError().isUserCancelled {
                    _sendError.send(error)
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }

                if let transactionURL = explorerUrl(from: result.hash) {
                    _transactionURL.send(transactionURL)
                }
                _transactionTime.send(Date())
            }
            .store(in: &bag)
    }

    private func bind() {
        _destinationText
            .dropFirst()
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.destination.send(nil)
                self?._isValidatingDestination.send(true)
            })
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.validateDestination()
            }
            .store(in: &bag)

        _destinationAdditionalFieldText
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.validateDestinationAdditionalField()
            }
            .store(in: &bag)

        Publishers.CombineLatest3(_amount, fee, _isFeeIncluded)
            .removeDuplicates {
                $0 == $1
            }
            .sink { [weak self] amount, fee, isFeeIncluded in
                self?.updateAndValidateAmount(amount, fee: fee, isFeeIncluded: isFeeIncluded)
            }
            .store(in: &bag)

        Publishers.CombineLatest(amount, destination)
            .removeDuplicates {
                $0 == $1
            }
            .withWeakCaptureOf(self)
            .flatMap { (self, parameters) -> AnyPublisher<FeeUpdateResult, Error> in
                self.updateFees(amount: parameters.0, destination: parameters.1)
                    .catch { _ in
                        Empty<FeeUpdateResult, Error>()
                    }
                    .eraseToAnyPublisher()
            }
            .sink()
            .store(in: &bag)

        _feeValues
            .sink { [weak self] feeValues in
                guard
                    let self,
                    let selectedFee = feeValues[selectedFeeOption],
                    let selectedFeeValue = selectedFee.value
                else {
                    return
                }

                fee.send(selectedFeeValue)

                if let customFee = feeValues[.custom]?.value,
                   let ethereumFeeParameters = customFee.parameters as? EthereumFeeParameters,
                   !didSetCustomFee {
                    _customFee.send(customFee)
                    _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
                    _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
                }
            }
            .store(in: &bag)

        #warning("[REDACTED_TODO_COMMENT]")
        Publishers.CombineLatest3(amount, destination, fee)
            .removeDuplicates {
                $0 == $1
            }
            .map { [weak self] amount, destination, fee -> Result<BlockchainSdk.Transaction, Error> in
                guard
                    let self,
                    let amount,
                    let destination,
                    let fee
                else {
                    return .failure(ValidationError.invalidAmount)
                }

                do {
                    let transaction = try walletModel.transactionCreator.createTransaction(
                        amount: amount,
                        fee: fee,
                        destinationAddress: destination
                    )
                    return .success(transaction)
                } catch {
                    AppLog.shared.debug("Failed to create transaction")
                    return .failure(error)
                }
            }
            .sink { [weak self] result in
                switch result {
                case .success(let transaction):
                    self?.transaction.send(transaction)
                    self?._transactionCreationError.send(nil)
                case .failure(let error):
                    self?.transaction.send(nil)
                    self?._transactionCreationError.send(error)
                }
            }
            .store(in: &bag)

        if let withdrawalValidator = walletModel.withdrawalValidator {
            transaction
                .map { transaction in
                    guard let transaction else { return nil }
                    return withdrawalValidator.withdrawalSuggestion(amount: transaction.amount, fee: transaction.fee.amount)
                }
                .sink { [weak self] in
                    self?._withdrawalSuggestion.send($0)
                }
                .store(in: &bag)
        }
    }

    @discardableResult
    private func updateFees(amount: Amount?, destination: String?) -> AnyPublisher<FeeUpdateResult, Error> {
        if let feeUpdatePublisher {
            return feeUpdatePublisher.eraseToAnyPublisher()
        }

        guard let amount, let destination else {
            _feeValues.send([:])
            return .anyFail(error: WalletError.failedToGetFee)
        }

        let oldFee = fee.value
        let publisher = walletModel
            .getFee(amount: amount, destination: destination)
            .withWeakCaptureOf(self)
            .map { (self, fees) in
                self.feeValues(fees)
            }
            .handleEvents(receiveOutput: { [weak self] feeValues in
                self?._feeValues.send(feeValues)
            }, receiveCompletion: { [weak self] completion in
                guard let self else { return }

                feeUpdatePublisher = nil

                if case .failure = completion {
                    let feeValuePairs: [(FeeOption, LoadingValue<Fee>)] = feeOptions.map { ($0, .failedToLoad(error: WalletError.failedToGetFee)) }
                    let feeValues = Dictionary(feeValuePairs, uniquingKeysWith: { v1, _ in v1 })
                    _feeValues.send(feeValues)
                }
            })
            .withWeakCaptureOf(self)
            .tryMap { (self, feeValues) in
                guard
                    let selectedFee = feeValues[self.selectedFeeOption],
                    let selectedFeeValue = selectedFee.value
                else {
                    throw WalletError.failedToGetFee
                }
                return FeeUpdateResult(oldFee: oldFee?.amount, newFee: selectedFeeValue.amount)
            }
            .eraseToAnyPublisher()

        feeUpdatePublisher = publisher

        return publisher
    }

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }

    // MARK: - Amount

    func setAmount(_ amount: Amount?) {
        let newAmount: Amount? = (amount?.isZero ?? true) ? nil : amount

        guard _amount.value != newAmount else { return }

        _amount.send(newAmount)
    }

    private func updateAndValidateAmount(_ newAmount: Amount?, fee: Fee?, isFeeIncluded: Bool) {
        let validatedAmount: Amount?
        let amountError: Error?
        let feeError: Error?

        if let newAmount {
            do {
                let amount: Amount
                if let fee,
                   isFeeIncluded {
                    amount = newAmount - fee.amount
                } else {
                    amount = newAmount
                }

                if let fee {
                    try walletModel.transactionCreator.validate(amount: amount, fee: fee)
                } else {
                    try walletModel.transactionCreator.validate(amount: amount)
                }

                validatedAmount = amount
                amountError = nil
                feeError = nil
            } catch let validationError {
                validatedAmount = nil
                if fee != nil {
                    amountError = nil
                    feeError = validationError
                } else {
                    amountError = validationError
                    feeError = nil
                }
            }
        } else {
            validatedAmount = nil
            amountError = nil
            feeError = nil
        }

        amount.send(validatedAmount)
        _amountError.send(amountError)
        _feeError.send(feeError)
    }

    // MARK: - Destination and memo

    func setDestination(_ address: String) {
        _destinationText.send(address)

        let hasEmbeddedAdditionalField = addressService.hasEmbeddedAdditionalField(address: address)
        _additionalFieldEmbeddedInAddress.send(hasEmbeddedAdditionalField)

        if hasEmbeddedAdditionalField {
            setDestinationAdditionalField("")
        }
    }

    func setDestinationAdditionalField(_ additionalField: String) {
        _destinationAdditionalFieldText.send(additionalField)
    }

    private func validateDestination() {
        destinationResolutionRequest?.cancel()

        destinationResolutionRequest = runTask(in: self) { `self` in
            let destination: String?
            let error: Error?
            do {
                destination = try await self.addressService.validate(address: self._destinationText.value)

                guard !Task.isCancelled else { return }

                error = nil
            } catch let addressError {
                guard !Task.isCancelled else { return }

                destination = nil
                error = addressError
            }

            await runOnMain {
                self.destination.send(destination)
                self._destinationError.send(error)
                self._isValidatingDestination.send(false)
            }
        }
    }

    private func validateDestinationAdditionalField() {
        let error: Error?
        let transactionParameters: TransactionParams?
        do {
            let parametersBuilder = SendTransactionParametersBuilder(blockchain: walletModel.blockchainNetwork.blockchain)
            transactionParameters = try parametersBuilder.transactionParameters(from: _destinationAdditionalFieldText.value)
            error = nil
        } catch let transactionParameterError {
            transactionParameters = nil
            error = transactionParameterError
        }

        self.transactionParameters = transactionParameters
        _destinationAdditionalFieldError.send(error)
    }

    // MARK: - Fees

    func didSelectFeeOption(_ feeOption: FeeOption) {
        guard let newFee = _feeValues.value[feeOption]?.value else {
            return
        }

        _selectedFeeOption.send(feeOption)
        fee.send(newFee)
    }

    func didChangeFeeInclusion(_ isFeeIncluded: Bool) {
        _isFeeIncluded.send(isFeeIncluded)
    }

    func didChangeCustomFee(_ value: Fee?) {
        didSetCustomFee = true
        _customFee.send(value)
        fee.send(value)

        if let ethereumParams = value?.parameters as? EthereumFeeParameters {
            _customFeeGasLimit.send(ethereumParams.gasLimit)
            _customFeeGasPrice.send(ethereumParams.gasPrice)
        }
    }

    func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        _customFeeGasPrice.send(value)
        recalculateCustomFee()
    }

    func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        _customFeeGasLimit.send(value)
        recalculateCustomFee()
    }

    private func recalculateCustomFee() {
        let newFee: Fee?
        if let gasPrice = _customFeeGasPrice.value,
           let gasLimit = _customFeeGasLimit.value,
           let gasInWei = (gasPrice * gasLimit).decimal {
            let amount = Amount(with: blockchain, value: gasInWei / blockchain.decimalValue)
            newFee = Fee(amount, parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice))
        } else {
            newFee = nil
        }

        didSetCustomFee = true
        _customFee.send(newFee)
        fee.send(newFee)
    }

    private func feeValues(_ fees: [Fee]) -> [FeeOption: LoadingValue<Fee>] {
        switch fees.count {
        case 1:
            return [
                .market: .loaded(fees[0]),
            ]
        case 3:
            var fees: [FeeOption: LoadingValue<Fee>] = [
                .slow: .loaded(fees[0]),
                .market: .loaded(fees[1]),
                .fast: .loaded(fees[2]),
            ]

            if feeOptions.contains(.custom) {
                if let customFee = _customFee.value,
                   didSetCustomFee {
                    fees[.custom] = .loaded(customFee)
                } else {
                    fees[.custom] = fees[.market]
                }
            }

            return fees
        default:
            return [:]
        }
    }
}

// MARK: - Subview model inputs

extension SendModel: SendAmountViewModelInput {
    var blockchain: BlockchainSdk.Blockchain {
        walletModel.blockchainNetwork.blockchain
    }

    var amountType: BlockchainSdk.Amount.AmountType {
        walletModel.amountType
    }

    var amountInputPublisher: AnyPublisher<BlockchainSdk.Amount?, Never> {
        _amount.eraseToAnyPublisher()
    }

    #warning("TODO")
    var errorPublisher: AnyPublisher<Error?, Never> {
        _amountError.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<Error?, Never> { _amountError.eraseToAnyPublisher() }
}

extension SendModel: SendDestinationViewModelInput {
    var isValidatingDestination: AnyPublisher<Bool, Never> { _isValidatingDestination.eraseToAnyPublisher() }

    var destinationTextPublisher: AnyPublisher<String, Never> { _destinationText.eraseToAnyPublisher() }
    var destinationAdditionalFieldTextPublisher: AnyPublisher<String, Never> { _destinationAdditionalFieldText.eraseToAnyPublisher() }

    var destinationError: AnyPublisher<Error?, Never> { _destinationError.eraseToAnyPublisher() }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { _destinationAdditionalFieldError.eraseToAnyPublisher() }

    var networkName: String { walletModel.blockchainNetwork.blockchain.displayName }

    var additionalFieldType: SendAdditionalFields? {
        let field = SendAdditionalFields.fields(for: walletModel.blockchainNetwork.blockchain)
        switch field {
        case .destinationTag, .memo:
            return field
        case .none:
            return nil
        }
    }

    var additionalFieldEmbeddedInAddress: AnyPublisher<Bool, Never> {
        _additionalFieldEmbeddedInAddress.eraseToAnyPublisher()
    }

    var blockchainNetwork: BlockchainNetwork {
        walletModel.blockchainNetwork
    }

    var walletPublicKey: Wallet.PublicKey {
        walletModel.wallet.publicKey
    }

    var currencySymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    var walletAddresses: [String] {
        walletModel.wallet.addresses.map { $0.value }
    }

    var transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never> {
        walletModel.transactionHistoryPublisher
    }
}

extension SendModel: SendFeeViewModelInput {
    var selectedFeeOption: FeeOption {
        _selectedFeeOption.value
    }

    #warning("TODO")
    var feeOptions: [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            var options: [FeeOption] = [.slow, .market, .fast]
            if blockchain.isEvm {
                options.append(.custom)
            }
            return options
        } else {
            return [.market]
        }
    }

    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> {
        _feeValues.eraseToAnyPublisher()
    }

    var tokenItem: TokenItem {
        walletModel.tokenItem
    }

    var customGasLimit: BigUInt? {
        _customFeeGasLimit.value
    }

    var customFeePublisher: AnyPublisher<Fee?, Never> {
        _customFee.eraseToAnyPublisher()
    }

    var customGasPricePublisher: AnyPublisher<BigUInt?, Never> {
        _customFeeGasPrice.eraseToAnyPublisher()
    }

    var customGasLimitPublisher: AnyPublisher<BigUInt?, Never> {
        _customFeeGasLimit.eraseToAnyPublisher()
    }

    var canIncludeFeeIntoAmount: Bool {
        sendType.canIncludeFeeIntoAmount && walletModel.amountType == walletModel.feeTokenItem.amountType
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }
}

extension SendModel: SendSummaryViewModelInput {
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> {
        _destinationAdditionalFieldText
            .map { [weak self] in
                guard
                    !$0.isEmpty,
                    let additionalFields = self?.additionalFieldType
                else {
                    return nil
                }
                return (additionalFields, $0)
            }
            .eraseToAnyPublisher()
    }

    var amountPublisher: AnyPublisher<Amount?, Never> {
        amount.eraseToAnyPublisher()
    }

    var feeValuePublisher: AnyPublisher<BlockchainSdk.Fee?, Never> {
        fee.eraseToAnyPublisher()
    }

    var feeOptionPublisher: AnyPublisher<FeeOption, Never> {
        _selectedFeeOption.eraseToAnyPublisher()
    }

    var canEditAmount: Bool {
        sendType.predefinedAmount == nil
    }

    var canEditDestination: Bool {
        sendType.predefinedDestination == nil
    }

    var isSending: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }
}

extension SendModel: SendFinishViewModelInput {
    var amountValue: Amount? {
        amount.value
    }

    var destinationText: String? {
        destination.value
    }

    var additionalField: (SendAdditionalFields, String)? {
        guard let additionalFieldType else { return nil }

        return (additionalFieldType, _destinationAdditionalFieldText.value)
    }

    var feeValue: Fee? {
        fee.value
    }

    var feeText: String {
        fee.value?.amount.string() ?? ""
    }

    var transactionTime: Date? {
        _transactionTime.value
    }

    var transactionURL: URL? {
        _transactionURL.value
    }
}

extension SendModel: SendNotificationManagerInput {
    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionCreationError.eraseToAnyPublisher()
    }

    var withdrawalSuggestion: AnyPublisher<WithdrawalSuggestion?, Never> {
        _withdrawalSuggestion.eraseToAnyPublisher()
    }
}
