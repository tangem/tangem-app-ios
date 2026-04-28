//
//  SwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SwapPairUpdateHandler {
    /// - Parameter isFullRefresh: `true` when the token changed, `false` for destination-address-only updates.
    func handlePairChange(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?,
        isFullRefresh: Bool
    ) async throws -> SwapPairUpdateResult
}

struct SwapPairUpdateResult {
    let expressResult: ExpressManagerUpdatingResult

    /// The amount-state update to apply after the pair change.
    /// - `nil` means "keep current amounts unchanged" (no-op).
    /// - Each non-nil case fully specifies the post-change amount state, including direction.
    let amountUpdate: AmountUpdate?

    enum AmountUpdate {
        /// Clear the computed complementary; used when there is no source amount to quote against.
        case clearComplementary

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
