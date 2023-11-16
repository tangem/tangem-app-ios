//
//  SendFinishViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendFinishViewModelInputMock: SendFinishViewModelInput {
    var amountTextBinding: Binding<String> { .constant("100,00") }
    var destinationTextBinding: Binding<String> { .constant("0x0123123") }
    var feeTextBinding: Binding<String> { .constant("Fee") }
    var transactionURL: AnyPublisher<URL?, Never> { .just(output: nil) }
}
