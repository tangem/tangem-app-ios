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

class SendSummaryInteractorMock: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<AttributedString?, Never> { .just(output: "123124$ (34151 USDT)") }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { .just(output: false) }
}
