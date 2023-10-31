//
//  SendModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI
import Combine

class SendModel: ObservableObject {
    @Published var amountText: String = ""
    @Published var destinationText: String = ""
    @Published var destinationAdditionalFieldText: String = ""
    @Published var feeText: String = ""

    @Published var amount: Decimal?
    @Published var destination: String?
    @Published var destinationAdditionalField: String?

    var amountTextBinding: Binding<String> {
        Binding(get: { self.amountText }, set: { self.setAmount($0) })
    }

    var destinationTextBinding: Binding<String> {
        Binding(get: { self.destinationText }, set: { self.setDestination($0) })
    }

    var destinationAdditionalFieldTextBinding: Binding<String> {
        Binding(get: { self.destinationAdditionalFieldText }, set: { self.setDestinationAdditionalField($0) })
    }

    var feeTextBinding: Binding<String> {
        Binding(get: { self.feeText }, set: { self.feeText = $0 })
    }

    var amountError: AnyPublisher<Error?, Never> {
        _amountError.eraseToAnyPublisher()
    }

    private var _amountError = CurrentValueSubject<Error?, Never>(nil)

    var destinationError: AnyPublisher<Error?, Never> {
        _destinationError.eraseToAnyPublisher()
    }

    private var _destinationError = CurrentValueSubject<Error?, Never>(nil)

    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> {
        _destinationAdditionalFieldError.eraseToAnyPublisher()
    }

    private var _destinationAdditionalFieldError = CurrentValueSubject<Error?, Never>(nil)

    init() {
        validateAmount()
    }

    func send() {
        print("SEND")
    }

    func stepValid(_ step: SendStep) -> AnyPublisher<Bool, Never> {
        switch step {
        case .amount:
            return amountError
                .map {
                    $0 == nil
                }
                .eraseToAnyPublisher()
        case .destination:
            return Publishers.CombineLatest(destinationError, destinationAdditionalFieldError)
                .map {
                    $0 == nil && $1 == nil
                }
                .eraseToAnyPublisher()
        default:
            // [REDACTED_TODO_COMMENT]
            return Just(true)
                .eraseToAnyPublisher()
        }
    }

    private func setAmount(_ amountText: String) {
        self.amountText = amountText

        if let amount = Decimal(string: amountText, locale: Locale.current) {
            self.amount = amount
        } else {
            amount = nil
        }

        validateAmount()
    }

    private func validateAmount() {
        let error: Error?
        let availableAmount: Decimal = 200
        if let amount, amount <= availableAmount {
            error = nil
        } else {
            error = SendError.notEnoughMoney
        }
        _amountError.send(error)
    }

    private func setDestination(_ text: String) {
        destinationText = text
        validateDestination()
    }

    private func validateDestination() {
        let destination: String?
        let error: Error?
        if destinationText.hasPrefix("0x"), destinationText.count == 42 {
            destination = destinationText
            error = nil
        } else {
            destination = nil
            error = SendError.invalidAddress
        }
        self.destination = destination
        _destinationError.send(error)
    }

    private func setDestinationAdditionalField(_ text: String) {
        destinationAdditionalFieldText = text
        validateDestinationAdditionalField()
    }

    private func validateDestinationAdditionalField() {
        let destinationAdditionalField: String?
        let error: Error?
        if destinationAdditionalFieldText.isEmpty || destinationAdditionalFieldText.allSatisfy({ $0.isNumber }) {
            destinationAdditionalField = destinationAdditionalFieldText
            error = nil
        } else {
            destinationAdditionalField = nil
            error = SendError.invalidDestinationAdditionalField
        }
        self.destinationAdditionalField = destinationAdditionalField
        _destinationAdditionalFieldError.send(error)
    }
}

enum SendError {
    case notEnoughMoney
    case invalidAddress
    case invalidDestinationAdditionalField
}

extension SendError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notEnoughMoney:
            return "Not enough money"
        case .invalidAddress:
            return "Invalid address"
        case .invalidDestinationAdditionalField:
            return "Invalid memo"
        }
    }
}

extension SendModel: SendAmountInput, SendAmountValidator, SendDestinationInput, SendDestinationValidator, SendFeeInput, SendSummaryInput {}
