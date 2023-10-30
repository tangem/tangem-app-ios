//
//  SendModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

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
    
    init() {
        
    }
    
    private func setAmount(_ amountText: String) {
        if let amount = Decimal(string: amountText, locale: Locale.current) {
            self.amount = amount
        } else {
            self.amount = nil
        }
    }
}

extension SendModel: SendAmountInput, SendDestinationInput, SendFeeInput{}
