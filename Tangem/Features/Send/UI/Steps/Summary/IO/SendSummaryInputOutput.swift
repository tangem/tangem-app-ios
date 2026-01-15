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
import TangemStaking
import TangemExpress

protocol SendSummaryInput: AnyObject {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> { get }
}

extension SendSummaryInput {
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}

protocol SendSummaryOutput: AnyObject {}

enum SendSummaryTransactionData {
    case send(amount: Decimal, fee: TokenFee)
    case staking(amount: SendAmount, schedule: RewardScheduleType)
    case swap(amount: Decimal?, fee: TokenFee?, provider: ExpressProvider)
}
