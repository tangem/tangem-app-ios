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

    func handlePairChange(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?,
        isFullRefresh: Bool
    ) async throws -> SwapPairUpdateResult {
        if FeatureProvider.isAvailable(.swapPipelineV2) {
            let cachedPairs = await expressPairsRepository.getPairs(from: source.currency)
            let isPairCached = cachedPairs.contains { $0.destination == destination.currency.asCurrency }

            if !isPairCached {
                try await expressPairsRepository.updatePairs(
                    for: source.currency,
                    userWalletInfo: source.userWalletInfo
                )
            }
        }

        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            // No source amount — clear stale receive amount and return pair result
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: .clearComplementary)
        }

        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapPairUpdateResult.AmountUpdate = result.selected?.getState().quote.map { quote in
            .anchorOnSource(
                source: sourceAmount,
                receive: quote.expectAmount,
                sourceCurrencyId: source.tokenItem.currencyId,
                receiveCurrencyId: destination.tokenItem.currencyId
            )
        } ?? .clearComplementary

        return SwapPairUpdateResult(expressResult: result, amountUpdate: amountUpdate)
    }
}
