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
    private let destinationAdditionalField = CurrentValueSubject<String?, Never>(nil)
    private let fee = CurrentValueSubject<Fee?, Never>(nil)

    private let transaction = CurrentValueSubject<BlockchainSdk.Transaction?, Never>(nil)

    // MARK: - Raw data

    private var _amount = CurrentValueSubject<Amount?, Never>(nil)
    private var _destinationText: String = ""
    private var _destinationAdditionalFieldText: String = ""
    private var _feeText: String = ""

    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _transactionTime = CurrentValueSubject<Date?, Never>(nil)

    // MARK: - Errors (raw implementation)

    private let _amountError = CurrentValueSubject<Error?, Never>(nil)
    private let _destinationError = CurrentValueSubject<Error?, Never>(nil)
    private let _destinationAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)

    // MARK: - Private stuff

    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let addressService: SendAddressService
    private let sendType: SendType
    private var destinationResolutionRequest: Task<Void, Error>?
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

        validateAmount()
        validateDestination()
        validateDestinationAdditionalField()
        bind()
    }

    func useMaxAmount() {
        let amountType = walletModel.amountType
        if let amount = walletModel.wallet.amounts[amountType] {
            setAmount(amount)
        }

        #warning("[REDACTED_TODO_COMMENT]")
    }

    func send() {
        guard var transaction = transaction.value else {
            return
        }

        #warning("[REDACTED_TODO_COMMENT]")
        #warning("[REDACTED_TODO_COMMENT]")
        #warning("[REDACTED_TODO_COMMENT]")

        _isSending.send(true)
        walletModel.send(transaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }

                _isSending.send(false)

                print("SEND FINISH ", completion)
                #warning("[REDACTED_TODO_COMMENT]")
            } receiveValue: { [weak self] result in
                guard let self else { return }

                _transactionTime.send(Date())
            }
            .store(in: &bag)
    }

    private func bind() {
        #warning("[REDACTED_TODO_COMMENT]")
        Publishers.CombineLatest(amount, destination)
            .flatMap { [weak self] amount, destination -> AnyPublisher<[Fee], Never> in
                guard
                    let self,
                    let amount,
                    let destination
                else {
                    return .just(output: [])
                }

                #warning("[REDACTED_TODO_COMMENT]")
                return walletModel
                    .getFee(amount: amount, destination: destination)
                    .receive(on: DispatchQueue.main)
                    .catch { [weak self] error in
                        #warning("[REDACTED_TODO_COMMENT]")
                        return Just([Fee]())
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .sink { [weak self] fees in
                guard let self else { return }

                #warning("[REDACTED_TODO_COMMENT]")
                fee.send(fees.first)

                print("fetched fees:", fees)
            }
            .store(in: &bag)

        #warning("[REDACTED_TODO_COMMENT]")
        Publishers.CombineLatest4(amount, destination, destinationAdditionalField, fee)
            .map { [weak self] amount, destination, destinationAdditionalField, fee -> BlockchainSdk.Transaction? in
                guard
                    let self,
                    let amount,
                    let destination,
                    let fee
                else {
                    return nil
                }

                #warning("[REDACTED_TODO_COMMENT]")
                return try? walletModel.createTransaction(
                    amountToSend: amount,
                    fee: fee,
                    destinationAddress: destination
                )
            }
            .sink { transaction in
                self.transaction.send(transaction)
                print("TX built", transaction != nil)
            }
            .store(in: &bag)
    }

    // MARK: - Amount

    func setAmount(_ amount: Amount?) {
        guard _amount.value != amount else { return }

        _amount.send(amount)
        validateAmount()
    }

    private func validateAmount() {
        let amount: Amount?
        let error: Error?

        #warning("validate")
        amount = _amount.value
        error = nil

        self.amount.send(amount)
        _amountError.send(error)
    }

    // MARK: - Destination and memo

    private func setDestination(_ destinationText: String) {
        _destinationText = destinationText
        validateDestination()
    }

    private func validateDestination() {
        #warning("[REDACTED_TODO_COMMENT]")
        destinationResolutionRequest?.cancel()

        destination.send(nil)
        destinationResolutionRequest = runTask(in: self) { `self` in
            let destination: String?
            let error: Error?
            do {
                destination = try await self.addressService.validate(address: self._destinationText)

                guard !Task.isCancelled else { return }

                error = nil

            } catch let addressError {
                guard !Task.isCancelled else { return }

                destination = nil
                error = addressError
            }

            self.destination.send(destination)
            self._destinationError.send(error)
        }
    }

    private func setDestinationAdditionalField(_ destinationAdditionalFieldText: String) {
        _destinationAdditionalFieldText = destinationAdditionalFieldText
        validateDestinationAdditionalField()
    }

    private func validateDestinationAdditionalField() {
        let destinationAdditionalField: String?
        let error: Error?

        #warning("validate")
        destinationAdditionalField = _destinationAdditionalFieldText
        error = nil

        self.destinationAdditionalField.send(destinationAdditionalField)
        _destinationAdditionalFieldError.send(error)
    }

    // MARK: - Fees

    private func setFee(_ feeText: String) {
        #warning("set and validate")
        _feeText = feeText
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

    var amountPublisher: AnyPublisher<BlockchainSdk.Amount?, Never> {
        _amount.eraseToAnyPublisher()
    }

    #warning("TODO")
    var errorPublisher: AnyPublisher<Error?, Never> {
        _amountError.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<Error?, Never> { _amountError.eraseToAnyPublisher() }
}

extension SendModel: SendDestinationViewModelInput {
    var destinationTextBinding: Binding<String> { Binding(get: { self._destinationText }, set: { self.setDestination($0) }) }
    var destinationAdditionalFieldTextBinding: Binding<String> { Binding(get: { self._destinationAdditionalFieldText }, set: { self.setDestinationAdditionalField($0) }) }
    var destinationError: AnyPublisher<Error?, Never> { _destinationError.eraseToAnyPublisher() }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { _destinationAdditionalFieldError.eraseToAnyPublisher() }
}

extension SendModel: SendFeeViewModelInput {
    var feeTextBinding: Binding<String> { Binding(get: { self._feeText }, set: { self.setFee($0) }) }
}

extension SendModel: SendSummaryViewModelInput {
    #warning("TODO")
    var amountText: String {
        "100"
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
