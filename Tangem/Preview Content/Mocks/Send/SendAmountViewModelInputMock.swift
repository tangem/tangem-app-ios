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
    var amountInputPublisher: AnyPublisher<BlockchainSdk.Amount?, Never> { .just(output: nil) }

    var amountType: Amount.AmountType { .coin }

    var blockchain: Blockchain { .ethereum(testnet: false) }
    var amountError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func setAmount(_ amount: BlockchainSdk.Amount?) {}
    func useMaxAmount() {}
}
