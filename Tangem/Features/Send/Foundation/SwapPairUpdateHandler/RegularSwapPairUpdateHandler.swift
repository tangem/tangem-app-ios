//
//  RegularSwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Pair update handler for the regular swap flow.
/// No estimation on first selection. Always uses float (`.from`) direction.
final class RegularSwapPairUpdateHandler: SwapPairUpdateHandler {
    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository

    init(expressManager: ExpressManager, expressPairsRepository: ExpressPairsRepository) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
    }

    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        guard let source, let destination else {
            return nil
        }

        let pair = ExpressManagerSwappingPair(source: source, destination: destination)

        // No loading for pair with the transfer type
        if pair.isTransfer {
            return nil
        }

        // Always update only providers. Not reload rates
        return .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        let pair = ExpressManagerSwappingPair(source: source, destination: destination)

        if FeatureProvider.isAvailable(.swapPipelineV2), !pair.isTransfer {
            let cachedPairs = await expressPairsRepository.getPairs(from: source.currency)
            let isPairCached = cachedPairs.contains { $0.destination == destination.currency.asCurrency }

            if !isPairCached {
                try await expressPairsRepository.updatePairs(for: source.currency, userWalletInfo: source.userWalletInfo)
            }
        }

        // In regular swap we clear the cached amount type when the pair changes.
        let _ = await expressManager.update(amountType: .none)

        return try await expressManager.update(pair: pair)
    }
}
