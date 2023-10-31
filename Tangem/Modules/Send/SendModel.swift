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
    @Published var feeText: String = ""

    @Published var amount: Decimal?

    var amountTextBinding: Binding<String> {
        Binding(get: { self.amountText }, set: { self.setAmount($0) })
    }

    var destinationTextBinding: Binding<String> {
        Binding(get: { self.destinationText }, set: { self.destinationText = $0 })
    }

    var feeTextBinding: Binding<String> {
        Binding(get: { self.feeText }, set: { self.feeText = $0 })
    }
    
    var amountValid: AnyPublisher<Bool, Never> {
        _amountValid.eraseToAnyPublisher()
    }
    
    private var _amountValid = CurrentValueSubject<Bool, Never>(false)
    
    

    init() {
        validateAmount()
    }

    func send() {
        print("SEND")
    }

    private func setAmount(_ amountText: String) {
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
    
    
}

extension SendModel: SendAmountInput, SendAmountValidator, SendDestinationInput, SendFeeInput, SendSummaryInput {}
