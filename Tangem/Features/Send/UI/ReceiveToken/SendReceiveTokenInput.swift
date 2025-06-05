//
//  SendReceiveTokenInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

typealias SendReceiveTokenAmountOutput = SendAmountOutput

protocol SendReceiveTokenInput: AnyObject {
    var receiveToken: SendReceiveToken? { get }
    var receiveTokenPublisher: AnyPublisher<SendReceiveToken?, Never> { get }

    var receiveAmount: SendAmount? { get }
    var receiveAmountPublisher: AnyPublisher<SendAmount?, Never> { get }
}

protocol SendReceiveTokenOutput: AnyObject {
    func userDidSelect(token: SendReceiveToken)
}
