//
//  SendAmountViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
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
