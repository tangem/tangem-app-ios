//
//  SwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class SwapFeeProvider {
    private let swapManager: SwapManager

    private var feeOptions: [FeeOption] { [.market, .fast] }
    private var feeTokenItem: TokenItem { swapManager.swappingPair.sender.value!.feeTokenItem }

    init(swapManager: SwapManager) {
        self.swapManager = swapManager
    }
}

// MARK: - Private

private extension SwapFeeProvider {
    func mapToFees(state: SwapManagerState) -> [TokenFee] {
        switch swapManager.state {
        case .idle, .loading:
            return TokenFeeConverter.mapToLoadingSendFees(options: feeOptions, feeTokenItem: feeTokenItem)
        case .restriction(.requiredRefresh(let occurredError), _):
            return TokenFeeConverter.mapToFailureSendFees(options: feeOptions, feeTokenItem: feeTokenItem, error: occurredError)
        case let state:
            return TokenFeeConverter.mapToSendFees(options: feeOptions, feeTokenItem: feeTokenItem, fees: state.fees.fees.map(\.value))
        }
    }
}

// MARK: - SendFeeProvider

extension SwapFeeProvider: SendFeeProvider {
    var fees: [TokenFee] {
        mapToFees(state: swapManager.state)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        swapManager.statePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(state: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        swapManager.updateFees()
    }
}
