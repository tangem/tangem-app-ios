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

    init(swapManager: SwapManager) {
        self.swapManager = swapManager
    }
}

// MARK: - Private

private extension SwapFeeProvider {
    func mapToFees(state: SwapManagerState) -> LoadingResult<[SendFee], any Error> {
        switch swapManager.state {
        case .loading:
            return .loading
        case .restriction(.requiredRefresh(let occurredError), _):
            return .failure(occurredError)
        case let state:
            let fees = state.fees.fees.map { option, fee in
                SendFee(option: option, value: .success(fee))
            }

            return .success(fees)
        }
    }
}

// MARK: - SendFeeProvider

extension SwapFeeProvider: SendFeeProvider {
    var feeOptions: [FeeOption] {
        [.market, .fast]
    }

    var fees: LoadingResult<[SendFee], any Error> {
        mapToFees(state: swapManager.state)
    }

    var feesPublisher: AnyPublisher<LoadingResult<[SendFee], any Error>, Never> {
        swapManager.statePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(state: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        swapManager.updateFees()
    }
}
