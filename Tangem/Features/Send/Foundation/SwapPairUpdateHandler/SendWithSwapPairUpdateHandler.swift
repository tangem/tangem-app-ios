//
//  SendWithSwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Pair update handler for the send-via-swap flow.
final class SendWithSwapPairUpdateHandler: SwapPairUpdateHandler {
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
        // Pair update — populates availableProviders in CommonExpressManager
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        if !isFullRefresh {
            // Destination-only change: re-fetch quotes using the existing amountType
            // to preserve rate direction (e.g. .to for fixed-rate mode).
            let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(by: .pair)
            return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: nil)
        }

        guard let sourceAmount else {
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: nil)
        }

        let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(amountType: .from(sourceAmount))

        let amountUpdate: SwapPairUpdateResult.AmountUpdate?
        if let quote = quoteResult.selected?.getState().quote {
            amountUpdate = .setReceiveAmount(crypto: quote.expectAmount, currencyId: destination.tokenItem.currencyId)
        } else {
            amountUpdate = nil
        }

        return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }
}
