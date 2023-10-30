//
//  SendFeeViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

protocol SendFeeInput {
    var feeText: String { get set }
    var feeTextBinding: Binding<String> { get }
}

class SendFeeViewModel {
    var fee: Binding<String>

    init(input: SendFeeInput) {
        self.fee = input.feeTextBinding
    }
}
