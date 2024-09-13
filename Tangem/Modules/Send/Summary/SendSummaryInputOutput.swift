//
//  SendSummaryInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendSummaryInput: AnyObject {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}

enum SendSummaryTransactionData {
    case send(amount: Decimal, fee: Fee)
    case staking(amount: SendAmount, fee: Decimal, apr: Decimal)
}
