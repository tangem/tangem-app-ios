//
//  SendModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

class SendModel: ObservableObject {
    @Published var amountText: String = "100"
    var amountTextBinding: Binding<String> {
        Binding(get: { self.amountText }, set: { self.amountText = $0 })
    }
}

extension SendModel: SendAmountInput {}
