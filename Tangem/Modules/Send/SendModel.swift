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
    
    var amountValid: AnyPublisher<Bool, Never> {
        _amountValid.eraseToAnyPublisher()
    }
    
    private var _amountValid = CurrentValueSubject<Bool, Never>(false)
    
    
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
        case .destination:
            return Publishers.CombineLatest(destinationError, destinationAdditionalFieldError)
                .map {
                    $0 == nil && $1 == nil
                }
                .eraseToAnyPublisher()
        default:
            // TODO
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
        let valid: Bool
        if let amount {
            let availableAmount: Decimal = 200
            valid = (amount <= availableAmount)
        } else {
            valid = false
        }
        self._amountValid.send(valid)
    }
    
    private func setDestination(_ text: String) {
        self.destinationText = text
        validateDestination()
    }
    
    private func validateDestination() {
        let destination: String?
        let error: Error?
        if destinationText.hasPrefix("0x") && destinationText.count == 42 {
            destination = destinationText
            error = nil
        } else {
            destination = nil
            error = SendError.invalidAddress
        }
        self.destination = destination
        self._destinationError.send(error)
    }
    
    private func setDestinationAdditionalField(_ text: String) {
        self.destinationAdditionalFieldText = text
        validateDestinationAdditionalField()
    }
    
    private func validateDestinationAdditionalField() {
        let destinationAdditionalField: String?
        let error: Error?
        if (destinationAdditionalFieldText.isEmpty || destinationAdditionalFieldText.allSatisfy({ $0.isNumber })) {
            destinationAdditionalField = destinationAdditionalFieldText
            error = nil
        } else {
            destinationAdditionalField = nil
            error = SendError.invalidDestinationAdditionalField
        }
        self.destinationAdditionalField = destinationAdditionalField
        self._destinationAdditionalFieldError.send(error)
    }
}

enum SendError {
    case invalidAddress
    case invalidDestinationAdditionalField
}

extension SendError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Invalid address"
        case .invalidDestinationAdditionalField:
            return "Invalid memo"
        }
    }
}

extension SendModel: SendAmountInput, SendAmountValidator, SendDestinationInput, SendDestinationValidator, SendFeeInput, SendSummaryInput {}
