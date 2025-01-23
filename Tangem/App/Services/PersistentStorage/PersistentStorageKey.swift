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
    case pendingOnrampTransactions
    case pendingStakingTransactions
    case onrampPreference
    case cachedBalances
    case cachedQuotes

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
        case .pendingOnrampTransactions:
            return "onramp_pending_transactions"
        case .pendingStakingTransactions:
            return "staking_pending_transactions"
        case .onrampPreference:
            return "onramp_preference"
        case .cachedBalances:
            return "cached_balances"
        case .cachedQuotes:
            return "cached_quotes"
        }
    }
}
