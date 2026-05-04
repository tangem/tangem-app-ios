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

    init(expressManager: ExpressManager) {
        self.expressManager = expressManager
    }

    func handlePairChange(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?,
        isFullRefresh: Bool
    ) async throws -> SwapPairUpdateResult {
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            // No source amount — clear stale receive amount and return pair result
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: .clearReceiveAmount)
        }

        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapPairUpdateResult.AmountUpdate = result.selected?.getState().quote.map {
            SwapPairUpdateResult.AmountUpdate.setReceiveAmount(
                crypto: $0.expectAmount,
                currencyId: destination.tokenItem.currencyId
            )
        } ?? .clearReceiveAmount

        return SwapPairUpdateResult(expressResult: result, amountUpdate: amountUpdate)
    }
}
