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
    var userInputAmountValue: Amount? { nil }
    var amountError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func setAmount(_ decimal: Decimal?) {}
    func didChangeFeeInclusion(_ isFeeIncluded: Bool) {}
}
