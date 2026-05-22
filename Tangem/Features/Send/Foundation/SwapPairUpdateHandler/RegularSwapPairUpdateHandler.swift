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

    func updatePair(
        source: any SendSwapableToken,
        destination: any SendReceiveToken,
        selectedAmountType: ExpressAmountType?
    ) async throws -> SwapPairUpdateResult {
        if FeatureProvider.isAvailable(.swapPipelineV2) {
            let cachedPairs = await expressPairsRepository.getPairs(from: source.currency)
            let isPairCached = cachedPairs.contains { $0.destination == destination.currency.asCurrency }

            if !isPairCached {
                try await expressPairsRepository.updatePairs(for: source.currency, userWalletInfo: source.userWalletInfo)
            }
        }

        let pair = ExpressManagerSwappingPair(source: source, destination: destination)
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)
        return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: .clearReceiveAmount)
    }
}
