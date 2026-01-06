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

    private let sendFeeProvider: SendFeeProvider
    private let swapFeeProvider: SendFeeProvider

    init(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: SendFeeProvider,
        swapFeeProvider: SendFeeProvider
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendFeeProvider = sendFeeProvider
        self.swapFeeProvider = swapFeeProvider
    }
}

// MARK: - SendFeeProvider

extension SendWithSwapFeeProvider: SendFeeProvider {
    var fees: [SendFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeProvider.fees
        case .swap: swapFeeProvider.fees
        }
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
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
