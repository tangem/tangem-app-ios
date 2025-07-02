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
    var destination: SendAddress? { .init(value: "", source: .myWallet) }
    var destinationPublisher: AnyPublisher<SendAddress, Never> { .just(output: destination!) }

    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { .just(output: .empty(type: .memo)) }

    func destinationDidChanged(_ address: SendAddress?) {}

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {}
}
