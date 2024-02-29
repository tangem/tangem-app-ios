//
//  PersistentStorageKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    case cards
    case wallets(cid: String)
    case allWalletConnectSessions
    case walletConnectSessions(userWalletId: String)
    case pendingExpressTransactions

    var path: String {
        switch self {
        case .cards:
            return "scanned_cards"
        case .wallets(let cid):
            return "wallets_\(cid)"
        case .allWalletConnectSessions:
            return "wc_sessions"
        case .walletConnectSessions(let userWalletId):
            return "wc_sessions_\(userWalletId)"
        case .pendingExpressTransactions:
            return "express_pending_transactions"
        }
    }
}
