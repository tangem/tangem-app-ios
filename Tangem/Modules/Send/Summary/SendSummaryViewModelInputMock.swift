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
    var amountTextBinding: Binding<String> { .constant("100,00") }
    var destinationTextBinding: Binding<String> { .constant("0x0123123") }
    var feeTextBinding: Binding<String> { .constant("Fee") }
}
