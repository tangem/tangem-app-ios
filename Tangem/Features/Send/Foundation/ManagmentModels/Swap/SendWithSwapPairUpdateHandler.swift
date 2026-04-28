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
    private let balanceConverter = BalanceConverter()

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
            let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(by: .pairChange)
            return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: nil)
        }

        guard let sourceAmount else {
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: .clearComplementary)
        }

        let sourceCurrencyId = source.tokenItem.currencyId
        let receiveCurrencyId = destination.tokenItem.currencyId

        // Fixed-rate flow: any provider supports fixed AND we can compute a local initial receive
        // via cached fiat quotes. Anchor on .to(initialReceive) so TO stays put and FROM absorbs
        // server-side discrepancy.
        if pairResult.providers.contains(where: { $0.supportedRateTypes.contains(.fixed) }),
           let initialReceiveAmount = computeLocalReceiveAmount(
               sourceAmount: sourceAmount,
               sourceCurrencyId: sourceCurrencyId,
               receiveCurrencyId: receiveCurrencyId
           ) {
            let anchoredResult: ExpressManagerUpdatingResult = try await expressManager.update(
                amountType: .to(initialReceiveAmount),
                by: .pairChange
            )

            let refinedSource = anchoredResult.selected?.getState().quote?.fromAmount ?? sourceAmount

            return SwapPairUpdateResult(
                expressResult: anchoredResult,
                amountUpdate: .anchorOnReceive(
                    source: refinedSource,
                    receive: initialReceiveAmount,
                    sourceCurrencyId: sourceCurrencyId,
                    receiveCurrencyId: receiveCurrencyId
                )
            )
        }

        // Float-rate flow: no fixed-rate provider available, or no cached fiat rate.
        // Keep FROM as anchor; server computes TO.
        let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapPairUpdateResult.AmountUpdate = quoteResult.selected?
            .getState().quote.map { quote in
                .anchorOnSource(
                    source: sourceAmount,
                    receive: quote.expectAmount,
                    sourceCurrencyId: sourceCurrencyId,
                    receiveCurrencyId: receiveCurrencyId
                )
            } ?? .clearComplementary

        return SwapPairUpdateResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }

    private func computeLocalReceiveAmount(
        sourceAmount: Decimal,
        sourceCurrencyId: String?,
        receiveCurrencyId: String?
    ) -> Decimal? {
        guard let sourceCurrencyId,
              let receiveCurrencyId,
              let sourceFiat = balanceConverter.convertToFiat(sourceAmount, currencyId: sourceCurrencyId),
              let receive = balanceConverter.convertToCryptoFrom(fiatValue: sourceFiat, currencyId: receiveCurrencyId)
        else { return nil }
        return receive
    }
}
