//
//  SendSummaryInputOutputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdkLocal

class SendSummaryInputOutputMock: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> { .just(output: .none) }
}

class SendSummaryInteractorMock: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<String?, Never> { .just(output: "123124$ (34151 USDT)") }
    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }

    func setup(input: any SendSummaryInput, output: any SendSummaryOutput) {}
}
