//
//  PersistentStorageKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    case wallets(cid: String)
    case allWalletConnectSessionsOld
    case walletConnectSessions
    case pendingExpressTransactions
    case pendingOnrampTransactions
    case pendingStakingTransactions
    case onrampPreference

    var path: String {
        switch self {
        case .wallets(let cid):
            return "wallets_\(cid)"
        case .allWalletConnectSessionsOld:
            return "wc_sessions"
        case .walletConnectSessions:
            return "wallet_connect_sessions"
        case .pendingExpressTransactions:
            return "express_pending_transactions"
        case .pendingOnrampTransactions:
            return "onramp_pending_transactions"
        case .pendingStakingTransactions:
            return "staking_pending_transactions"
        case .onrampPreference:
            return "onramp_preference"
        }
    }
}
