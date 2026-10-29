//
//  TangemPayMoneyAccountAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum TangemPayMoneyAccountAction {
    case topup
    case withdraw
    case openYieldMode
    case reloadTransactionHistory
    case openTransactionDetails(id: TransactionRecord.ID)
    case openExplorer
    case selectMenuItem(TangemPayMoneyAccountMenuItem)
}
