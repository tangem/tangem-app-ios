//
//  SendFeeViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

protocol SendFeeViewModelInput {
    var feeTextBinding: Binding<String> { get }
}

class SendFeeViewModel {
    var fee: Binding<String>

    init(input: SendFeeViewModelInput) {
        fee = input.feeTextBinding
    }
}
