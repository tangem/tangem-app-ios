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

    func updatePair(
        source: SendSwapableToken,
        destination: SendReceiveToken
    ) async throws -> SwapPairUpdateResult {
        let pair = ExpressManagerSwappingPair(source: source, destination: destination)
        let pairResult = try await expressManager.update(pair: pair)

        guard let amountType = await expressManager.getAmountType() else {
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: nil)
        }

        let quoteResult = await expressManager.update(amountType: amountType)

        let quote = quoteResult.selected?.getState().quote
        let amountUpdate: SwapPairUpdateResult.AmountUpdate? = switch (amountType, quote) {
        case (.from, .some(let quote)): .setReceiveAmount(crypto: quote.expectAmount, currencyId: destination.tokenItem.currencyId)
        case (.to, .some(let quote)): .setSourceAmount(crypto: quote.fromAmount, currencyId: source.tokenItem.currencyId)
        case (_, .none): .none
        }

        return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }
}
