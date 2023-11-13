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

    // MARK: - Data

    private var amount = CurrentValueSubject<Decimal?, Never>(nil)
    private var destination = CurrentValueSubject<String?, Never>(nil)
    private var destinationAdditionalField = CurrentValueSubject<String?, Never>(nil)

    // MARK: - Raw data

    private var _amountText: String = ""
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

    func useMaxAmount() {
        setAmount("1000")
    }

    func send() {
        print("SEND")
    }

    // MARK: - Amount

    private func setAmount(_ amountText: String) {
        _amountText = amountText
        validateAmount()
    }

    private func validateAmount() {
        let amount: Decimal?
        let error: Error?

        #warning("validate")
        amount = Decimal(string: _amountText, locale: Locale.current) ?? 0
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
    var amountTextBinding: Binding<String> { Binding(get: { self._amountText }, set: { self.setAmount($0) }) }
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
    // Covered by other protocols
}
