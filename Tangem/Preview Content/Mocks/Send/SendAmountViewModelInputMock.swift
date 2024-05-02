//
//  SendAmountViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendAmountViewModelInputMock: SendAmountViewModelInput {
    var amountError: AnyPublisher<Error?, Never> {
        Just("Insufficient funds for transfer").eraseToAnyPublisher()
    }

    func setAmount(_ decimal: Amount?) {}
    func didChangeFeeInclusion(_ isFeeIncluded: Bool) {}
}
