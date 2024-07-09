//
//  SendSendDestinationInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendDestinationInputOutputMock: SendDestinationInput, SendDestinationOutput {
    var destinationPublisher: AnyPublisher<SendAddress, Never> { .just(output: .init(value: "", source: .myWallet)) }

    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> { .just(output: .empty(type: .memo)) }

    func destinationDidChanged(_ address: SendAddress?) {}

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {}
}
