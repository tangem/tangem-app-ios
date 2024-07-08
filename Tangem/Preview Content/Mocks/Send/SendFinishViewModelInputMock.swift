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
import BlockchainSdk

class SendFinishViewModelInputMock: SendFinishViewModelInput {
    var destinationText: String? { "0x123123123" }
    var additionalField: DestinationAdditionalFieldType { .filled(type: .memo, value: "123123", params: TONTransactionParams(memo: "123123")) }
    var userInputAmountValue: BlockchainSdk.Amount? { .init(with: .ethereum(testnet: false), type: .coin, value: 1) }
    var feeValue: SendFee? { .init(option: .market, value: .loaded(.init(Amount(with: .ethereum(testnet: false), value: 0.003)))) }
    var amountText: String { "100,00" }
    var feeText: String { "Fee" }
    var transactionTime: Date? { Date() }
    var transactionURL: URL? { URL(string: "google.com")! }
}
