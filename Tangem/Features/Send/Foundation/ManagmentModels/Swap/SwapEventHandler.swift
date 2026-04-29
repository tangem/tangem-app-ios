//
//  SwapEventHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Routes swap-related events into the express layer. Each event is named for
/// the cause, not the consequence — callers don't need to know whether a given
/// event triggers a provider reload, a re-quote, or just a CEX-data refresh.
protocol SwapEventHandler {
    // MARK: - Full refresh: providers + quotes

    /// Source token changed. Reload providers; re-quote.
    func sourceTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult

    /// Receive token changed. Reload providers; re-quote.
    func receiveTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult

    // MARK: - Partial: re-quote only (no provider reload)

    /// User-typed source amount changed. Debounce + re-quote in `.from` direction.
    func sourceAmountChanged(amount: Decimal?) async throws -> SwapEventResult

    /// User-typed receive amount changed. Debounce + re-quote in `.to` direction.
    func receiveAmountChanged(amount: Decimal?) async throws -> SwapEventResult

    // MARK: - CEX-only: refresh exchange data without disturbing direction or amounts

    /// Destination address changed. Re-fetch quotes using the existing `amountType`
    /// to preserve rate direction (e.g. `.to` for fixed-rate mode); does not reload providers.
    func destinationAddressChanged() async throws -> SwapEventResult

    /// User tapped a "refresh" notification button. Re-fetch quotes against the existing
    /// `amountType` and pair, surfacing fresh provider state without disturbing direction.
    func refreshRequested() async throws -> SwapEventResult
}

struct SwapEventResult {
    let expressResult: ExpressManagerUpdatingResult

    /// The amount-state update to apply after the event.
    /// - `nil` means "keep current amounts unchanged" (no-op).
    /// - Each non-nil case specifies what `applyAmountUpdate` should do.
    let amountUpdate: AmountUpdate?

    enum AmountUpdate {
        /// Clear the computed complementary; used when there is no source amount to quote against.
        case clearComplementary

        /// Set complementary only; userAmount unchanged. Used by amount-change events
        /// where direction was already set synchronously by the caller.
        /// SwapModel derives the currencyId from state since it depends on `userAmount`
        /// direction (receive token's id for `.source`, source token's id for `.receive`).
        case setComplementary(crypto: Decimal)

        /// Float-rate flow: source is the anchor, receive is server-computed.
        /// Applies as `userAmount = .source(source)`, `complementaryAmount = receive`.
        case anchorOnSource(
            source: Decimal,
            receive: Decimal,
            sourceCurrencyId: String?,
            receiveCurrencyId: String?
        )

        /// Fixed-rate flow: receive is the anchor (locally computed initial value),
        /// source is server-refined via a `.to(receive)` quote.
        /// Applies as `userAmount = .receive(receive)`, `complementaryAmount = source`.
        case anchorOnReceive(
            source: Decimal,
            receive: Decimal,
            sourceCurrencyId: String?,
            receiveCurrencyId: String?
        )
    }
}
