//
//  SendSummaryViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendSummaryViewModelInputMock: SendSummaryViewModelInput {
    var amountText: String { "100,00" }
    var canEditAmount: Bool { true }
    var canEditDestination: Bool { true }
    var destinationTextBinding: Binding<String> { .constant("0x0123123") }
    var feeTextBinding: Binding<String> { .constant("Fee") }
    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }

    func send() {}
}
