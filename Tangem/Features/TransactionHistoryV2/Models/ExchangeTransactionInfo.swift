//
//  ExchangeTransactionInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExchangeTransactionInfo: Hashable {
    let transaction: ExchangeTransaction

    /// - Note: Nullable since can be fetched asynchronously.
    let provider: ExpressProvider?

    /// Use this dictionary to resolve an `ExchangeTransaction`'s `ExpressCurrency` to a `TokenItem` for use in the UI layer.
    /// - Note: Cache misses are expected since this dictionary can be populated asynchronously.
    let cryptoCurrencies: [ExpressCurrency: TokenItem]
}
