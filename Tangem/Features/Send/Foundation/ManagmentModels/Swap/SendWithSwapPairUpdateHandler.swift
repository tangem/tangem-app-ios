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
/// Estimates receive amount via local rates on pair changes.
/// The TO token can only be changed while editing the TO field,
/// so we always use `.to(estimate)` to preserve direction and focus.
final class SendWithSwapPairUpdateHandler: SwapPairUpdateHandler {
    private let expressManager: ExpressManager
    private let balanceConverter = BalanceConverter()

    init(expressManager: ExpressManager) {
        self.expressManager = expressManager
    }

    func handlePairChange(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapPairUpdateResult {
        // Compute local estimate of the receive amount using source → destination rates
        var estimatedTo: Decimal?
        if let sourceAmount,
           let sourceCurrencyId = source.tokenItem.currencyId,
           let destCurrencyId = destination.tokenItem.currencyId {
            estimatedTo = try? await balanceConverter.convertCryptoToCrypto(
                sourceId: sourceCurrencyId,
                sourceAmount: sourceAmount,
                targetId: destCurrencyId
            ).rounded(scale: destination.tokenItem.decimalCount)
        }

        // Pair update — populates availableProviders in CommonExpressManager
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: nil)
        }

        // If local rate estimation succeeded, return it immediately.
        // The ViewModel's pendingReverseRecalculation mechanism will trigger
        // the actual .to(estimate) quote, preserving direction and focus.
        if let estimatedTo {
            let amountUpdate: SwapPairUpdateResult.AmountUpdate = .setReceiveAmount(
                crypto: estimatedTo,
                currencyId: destination.tokenItem.currencyId
            )
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: amountUpdate)
        }

        // Fallback: local rates unavailable — fetch a forward quote from Express
        // so that the receive amount is populated and pendingReverseRecalculation can fire.
        let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapPairUpdateResult.AmountUpdate? = quoteResult.selected?.getState().quote.map {
            .setReceiveAmount(crypto: $0.expectAmount, currencyId: destination.tokenItem.currencyId)
        }
        return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }
}
