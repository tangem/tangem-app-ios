//
//  SendReceiveTokenAmountInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol SendReceiveTokenAmountInput: AnyObject {
    var receiveAmount: LoadingResult<SendAmount?, any Error> { get }
    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, Error>, Never> { get }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> { get }
}

protocol SendReceiveTokenAmountOutput: AnyObject {
    func receiveAmountDidChanged(amount: SendAmount?)
}
