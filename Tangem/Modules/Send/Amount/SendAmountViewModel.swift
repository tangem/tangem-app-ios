//
//  SendAmountViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

class SendAmountViewModel {
    var amountText: Binding<String>

    init(amountText: Binding<String>) {
        self.amountText = amountText
    }
}
