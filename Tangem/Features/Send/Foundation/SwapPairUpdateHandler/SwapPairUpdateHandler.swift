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
    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> SwapPairUpdateResult
}

struct SwapPairUpdateResult {
    let expressResult: ExpressManagerUpdatingResult

    /// The amount field to update after the pair change.
    /// - `nil` means "keep current amounts unchanged" (no-op).
    /// - `.clearReceiveAmount` means "actively clear the receive field".
    let amountUpdate: AmountUpdate?

    enum AmountUpdate {
        case setReceiveAmount(crypto: Decimal, currencyId: String?)
        case setSourceAmount(crypto: Decimal, currencyId: String?)
        case clearReceiveAmount
    }
}
