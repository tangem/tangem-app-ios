//
//  SendAmountInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendAmountInputOutputMock: SendAmountInput, SendAmountOutput {
    var amount: SendAmount? { .none }
    var amountPublisher: AnyPublisher<SendAmount?, Never> { .just(output: amount) }

    func amountDidChanged(amount: SendAmount?) {}
}
