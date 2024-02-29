//
//  TokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenDetailsRoutable: AnyObject {
    func dismiss()
    func openFeeCurrency(for model: WalletModel, userWalletModel: UserWalletModel)
    func openPendingExpressTransactionDetails(
        for pendingTransaction: PendingExpressTransaction,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
