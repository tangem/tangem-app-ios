//
//  SendDestinationViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendDestinationViewModelInputMock: SendDestinationViewModelInput {
    var destinationTextPublisher: AnyPublisher<String, Never> {
        .just(output: "0x123123")
    }

    var destinationAdditionalFieldTextPublisher: AnyPublisher<String, Never> {
        .just(output: "Memo")
    }

    var destinationError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var networkName: String {
        "Ethereum"
    }

    var additionalField: SendAdditionalFields? {
        .memo
    }

    var suggestedWallets: [SendSuggestedDestinationWallet] {
        []
    }

    var recentTransactions: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> {
        .just(output: [])
    }
}
