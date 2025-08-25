//
//  SendReceiveTokenInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol SendReceiveTokenInput: AnyObject {
    var isReceiveTokenSelectionAvailable: Bool { get }

    var receiveToken: SendReceiveTokenType { get }
    var receiveTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> { get }
}

protocol SendReceiveTokenOutput: AnyObject {
    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void)
    func userDidRequestClearSelection()
}
