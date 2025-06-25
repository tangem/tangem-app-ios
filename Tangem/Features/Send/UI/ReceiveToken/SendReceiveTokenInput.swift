//
//  SendReceiveTokenInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

typealias SendReceiveTokenAmountOutput = SendAmountOutput

protocol SendReceiveTokenInput: AnyObject {
    var receiveToken: SendReceiveToken? { get }
    var receiveTokenPublisher: AnyPublisher<SendReceiveToken?, Never> { get }

    var receiveAmount: LoadingResult<SendAmount?, any Error> { get }
    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount?, Error>, Never> { get }
}

protocol SendReceiveTokenOutput: AnyObject {
    func userDidSelect(tokenItem: TokenItem?)
}
