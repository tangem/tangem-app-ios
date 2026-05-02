//
//  SendWithSwapEventHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Event handler for the send-via-swap flow. Picks fixed-rate provider when available;
/// otherwise falls through to float-rate (`.from`-direction) quoting.
final class SendWithSwapEventHandler: SwapEventHandler {
    private let expressManager: ExpressManager
    private let balanceConverter = BalanceConverter()

    init(expressManager: ExpressManager) {
        self.expressManager = expressManager
    }

    // MARK: - Token changes (full refresh)

    func sourceTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        try await fullRefresh(pair: pair, source: source, destination: destination, sourceAmount: sourceAmount)
    }

    /// Receive-token change: pair update + mode decision. Populates TO with the
    /// locally-recalculated value in fixed-rate mode; falls back to a server-quoted
    /// `.from()` refresh in float-rate mode. FROM recalc in fixed-rate mode is the
    /// caller's responsibility — `SwapModel.update(receive:)` chains
    /// `receiveAmountChanged` after this returns.
    func receiveTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            return SwapEventResult(expressResult: pairResult, amountUpdate: .clearComplementary)
        }

        let sourceCurrencyId = source.tokenItem.currencyId
        let receiveCurrencyId = destination.tokenItem.currencyId
        let hasFixedRate = pairResult.providers.contains { $0.supportedRateTypes.contains(.fixed) }

        if hasFixedRate,
           let initialReceive = computeLocalReceiveAmount(
               sourceAmount: sourceAmount,
               sourceCurrencyId: sourceCurrencyId,
               receiveTokenItem: destination.tokenItem
           ) {
            return SwapEventResult(
                expressResult: pairResult,
                amountUpdate: .anchorOnReceive(
                    source: sourceAmount,
                    receive: initialReceive,
                    sourceCurrencyId: sourceCurrencyId,
                    receiveCurrencyId: receiveCurrencyId
                )
            )
        }

        let quoteResult: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate = quoteResult.selected?
            .getState().quote.map { quote in
                .anchorOnSource(
                    source: sourceAmount,
                    receive: quote.expectAmount,
                    sourceCurrencyId: sourceCurrencyId,
                    receiveCurrencyId: receiveCurrencyId
                )
            } ?? .clearComplementary

        return SwapEventResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }

    // MARK: - Amount changes (re-quote only)

    func sourceAmountChanged(amount: Decimal?) async throws -> SwapEventResult {
        let amountType: ExpressAmountType? = amount.map { .from($0) }
        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: amountType,
            by: .amountChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate? = result.selected?.getState().quote.map { quote in
            .setComplementary(crypto: quote.expectAmount)
        }
        return SwapEventResult(expressResult: result, amountUpdate: amountUpdate)
    }

    func receiveAmountChanged(amount: Decimal?) async throws -> SwapEventResult {
        let amountType: ExpressAmountType? = amount.map { .to($0) }
        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: amountType,
            by: .amountChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate? = result.selected?.getState().quote.map { quote in
            .setComplementary(crypto: quote.fromAmount)
        }
        return SwapEventResult(expressResult: result, amountUpdate: amountUpdate)
    }

    // MARK: - CEX-only refreshes

    func destinationAddressChanged() async throws -> SwapEventResult {
        // Re-fetch quotes using the existing amountType to preserve rate direction.
        let result: ExpressManagerUpdatingResult = try await expressManager.update(by: .pairChange)
        return SwapEventResult(expressResult: result, amountUpdate: nil)
    }

    func refreshRequested() async throws -> SwapEventResult {
        let result: ExpressManagerUpdatingResult = try await expressManager.update(by: .pairChange)
        return SwapEventResult(expressResult: result, amountUpdate: nil)
    }

    // MARK: - Private

    /// Full refresh shared between source-token and receive-token changes:
    /// reload providers, then either anchor on locally-computed receive (fixed-rate flow)
    /// or anchor on source via float-rate quote.
    private func fullRefresh(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            return SwapEventResult(expressResult: pairResult, amountUpdate: .clearComplementary)
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
               receiveTokenItem: destination.tokenItem
           ) {
            let anchoredResult: ExpressManagerUpdatingResult = try await expressManager.update(
                amountType: .to(initialReceiveAmount),
                by: .pairChange
            )

            let refinedSource = anchoredResult.selected?.getState().quote?.fromAmount ?? sourceAmount

            return SwapEventResult(
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

        let amountUpdate: SwapEventResult.AmountUpdate = quoteResult.selected?
            .getState().quote.map { quote in
                .anchorOnSource(
                    source: sourceAmount,
                    receive: quote.expectAmount,
                    sourceCurrencyId: sourceCurrencyId,
                    receiveCurrencyId: receiveCurrencyId
                )
            } ?? .clearComplementary

        return SwapEventResult(expressResult: quoteResult, amountUpdate: amountUpdate)
    }

    private func computeLocalReceiveAmount(
        sourceAmount: Decimal,
        sourceCurrencyId: String?,
        receiveTokenItem: TokenItem
    ) -> Decimal? {
        guard let sourceCurrencyId,
              let receiveCurrencyId = receiveTokenItem.currencyId,
              let sourceFiat = balanceConverter.convertToFiat(sourceAmount, currencyId: sourceCurrencyId),
              let receive = balanceConverter.convertToCryptoFrom(fiatValue: sourceFiat, currencyId: receiveCurrencyId)
        else { return nil }
        // Express API rejects amounts with more fraction digits than the token supports.
        return receive.rounded(scale: receiveTokenItem.decimalCount, roundingMode: .down)
    }
}
