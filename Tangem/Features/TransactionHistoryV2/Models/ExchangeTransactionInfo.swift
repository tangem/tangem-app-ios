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
}
