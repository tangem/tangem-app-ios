//
//  SendAmountViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

protocol SendAmountInput {
    var amountText: String { get set }
    var amountTextBinding: Binding<String> { get }
}

class SendAmountViewModel {
    var amountText: Binding<String>

    init(input: SendAmountInput) {
        amountText = input.amountTextBinding
    }
}
