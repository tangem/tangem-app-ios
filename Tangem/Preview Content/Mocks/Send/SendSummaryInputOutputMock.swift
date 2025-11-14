//
//  SendSummaryInputOutputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendSummaryInputOutputMock: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> { .just(output: .none) }
}
