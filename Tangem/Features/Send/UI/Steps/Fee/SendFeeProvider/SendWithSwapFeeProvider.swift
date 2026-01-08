//
//  SendWithSwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class SendWithSwapFeeProvider {
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendFeeProvider: TokenFeeProvider
    private let swapFeeProvider: TokenFeeProvider

    init(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: TokenFeeProvider,
        swapFeeProvider: TokenFeeProvider
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendFeeProvider = sendFeeProvider
        self.swapFeeProvider = swapFeeProvider
    }
}

// MARK: - TokenFeeProvider

extension SendWithSwapFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeProvider.fees
        case .swap: swapFeeProvider.fees
        }
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        guard let receiveTokenInput else {
            assertionFailure("ReceiveTokenInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest3(
            receiveTokenInput.receiveTokenPublisher,
            sendFeeProvider.feesPublisher,
            swapFeeProvider.feesPublisher
        )
        .map { input, sendFees, swapFees in
            switch input {
            case .same: sendFees
            case .swap: swapFees
            }
        }
        .eraseToAnyPublisher()
    }

    func updateFees() {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeProvider.updateFees()
        case .swap: swapFeeProvider.updateFees()
        }
    }
}
