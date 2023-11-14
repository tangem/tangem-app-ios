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

    private(set) var isFiatCalculation: Bool = false

    // MARK: - Data

    private var amount = CurrentValueSubject<DecimalNumberTextField.DecimalValue?, Never>(nil)
    private var destination = CurrentValueSubject<String?, Never>(nil)
    private var destinationAdditionalField = CurrentValueSubject<String?, Never>(nil)

    // MARK: - Raw data

    private var _amount: DecimalNumberTextField.DecimalValue?
    private var _destinationText: String = ""
    private var _destinationAdditionalFieldText: String = ""
    private var _feeText: String = ""

    // MARK: - Errors (raw implementation)

    private var _amountError = CurrentValueSubject<Error?, Never>(nil)
    private var _destinationError = CurrentValueSubject<Error?, Never>(nil)
    private var _destinationAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)

    // MARK: - Public interface

    init() {
        validateAmount()
        validateDestination()
        validateDestinationAdditionalField()
    }

    func setIsFiatCalculation(_ isFiatCalculation: Bool) {
        self.isFiatCalculation = isFiatCalculation

        #warning("TODO")
    }

    func useMaxAmount() {
        #warning("TODO")
    }

    func send() {
        print("SEND")
    }

    // MARK: - Amount

    private func setAmount(_ amount: DecimalNumberTextField.DecimalValue?) {
        _amount = amount
        validateAmount()
    }

    private func validateAmount() {
        let amount: DecimalNumberTextField.DecimalValue?
        let error: Error?

        #warning("validate")
        amount = _amount
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
        let destination: String?
        let error: Error?

        #warning("validate")
        destination = _destinationText
        error = nil

        self.destination.send(destination)
        _destinationError.send(error)
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
    #warning("TODO")
    var walletName: String {
        "My Wallet (TODO)"
    }

    #warning("TODO")
    var balance: String {
        "2 130,88 USDT (2 129,92 $)"
    }

    #warning("TODO")
    var tokenIconName: String {
        "tether"
    }

    #warning("TODO")
    var tokenIconURL: URL? {
        TokenIconURLBuilder().iconURL(id: "tether")
    }

    #warning("TODO")
    var tokenIconCustomTokenColor: Color? {
        nil
    }

    #warning("TODO")
    var tokenIconBlockchainIconName: String? {
        "ethereum.fill"
    }

    #warning("TODO")
    var isCustomToken: Bool {
        false
    }

    #warning("TODO")
    var amountFractionDigits: Int {
        2
    }

    #warning("TODO")
    var amountAlternativePublisher: AnyPublisher<String, Never> {
        .just(output: "1 000 010,99 USDT")
    }

    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?> {
        Binding { self._amount } set: { self.setAmount($0) }
    }

    #warning("TODO")
    var errorPublisher: AnyPublisher<Error?, Never> {
        _amountError.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<Error?, Never> { _amountError.eraseToAnyPublisher() }

    #warning("TODO")
    var cryptoCurrencyCode: String {
        "USDT"
    }

    #warning("TODO")
    var fiatCurrencyCode: String {
        "USD"
    }
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

    // Covered by other protocols
}
