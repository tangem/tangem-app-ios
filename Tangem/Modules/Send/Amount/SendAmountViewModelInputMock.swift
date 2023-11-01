//
//  SendAmountViewModelInputMock.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import Combine

class SendAmountViewModelInputMock: SendAmountViewModelInput {
    var amountTextBinding: Binding<String> {
        .constant("100,00")
    }

    var amountError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
