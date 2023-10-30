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

    var amountTextBinding: Binding<String> {
        Binding(get: { self.amountText }, set: { self.amountText = $0 })
    }
    
    var destinationTextBinding: Binding<String> {
        Binding(get: { self.destinationText }, set: { self.destinationText = $0 })
    }
    
    var feeTextBinding: Binding<String> {
        Binding(get: { self.feeText }, set: { self.feeText = $0 })
    }
    
    init() {
        
    }
}

extension SendModel: SendAmountInput, SendDestinationInput, SendFeeInput{}
