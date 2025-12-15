//
//  PendingExpressTransactionsManagerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct PendingExpressTransactionsManagerBuilder {
    let userWalletId: String
    let tokenItem: TokenItem

    func makePendingExpressTransactionsManager(expressAPIProvider: ExpressAPIProvider) -> PendingExpressTransactionsManager {
        CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletId,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )
    }
}
