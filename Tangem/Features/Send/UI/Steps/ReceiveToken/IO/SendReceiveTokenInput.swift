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

    var receiveToken: LoadingResult<SendReceiveToken, any Error> { get }
    var receiveTokenPublisher: AnyPublisher<LoadingResult<SendReceiveToken, any Error>, Never> { get }
}

protocol SendReceiveTokenOutput: AnyObject {
    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void)
    func userDidRequestClearSelection()
}

// MARK: - Combined protocols

/// Combines receive token and receive amount into a single input protocol.
typealias SendReceiveInput = SendReceiveTokenInput & SendReceiveTokenAmountInput

/// Combines receive token and receive amount into a single output protocol.
typealias SendReceiveOutput = SendReceiveTokenOutput & SendReceiveTokenAmountOutput
