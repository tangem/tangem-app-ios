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
    let walletModel: any WalletModel

    func makePendingExpressTransactionsManager(expressAPIProvider: ExpressAPIProvider) -> PendingExpressTransactionsManager {
        CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletId,
            walletModel: walletModel,
            expressAPIProvider: expressAPIProvider
        )
    }
}
