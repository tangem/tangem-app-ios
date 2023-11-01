//
//  SendFeeViewModelInputMock.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import Combine

class SendFeeViewModelInputMock: SendFeeViewModelInput {
    var feeTextBinding: Binding<String> { .constant("Fee") }
}
