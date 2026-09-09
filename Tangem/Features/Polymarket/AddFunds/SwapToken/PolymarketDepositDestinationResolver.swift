//
//  PolymarketDepositDestinationResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PolymarketDepositDestinationResolver {
    private let destination: SendSwapableToken

    init(destination: SendSwapableToken) {
        self.destination = destination
    }
}

// MARK: - SwapDestinationTokenResolver

extension PolymarketDepositDestinationResolver: SwapDestinationTokenResolver {
    func resolveDestination(for source: SendSwapableToken) -> SendReceiveToken {
        destination
    }
}
