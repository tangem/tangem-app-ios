//
//  PersistentStorageKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    /// - Note: Superseded by `accounts(cid:)`, will be removed in future.
    case wallets(cid: String)
    /// - Note: Supersedes `wallets(cid:)`.
    case accounts(cid: String)
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
        case .accounts(let cid):
            return "accounts_\(cid)"
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

    /// Should the file be protected while the device is locked? For sensitive data.
    var shouldEnableCompleteFileProtection: Bool {
        switch self {
        case .accounts:
            false
        case .allWalletConnectSessionsOld:
            false
        case .onrampPreference:
            false
        case .pendingExpressTransactions:
            false
        case .pendingOnrampTransactions:
            false
        case .pendingStakingTransactions:
            false
        case .walletConnectSessions:
            false
        case .wallets:
            false
        }
    }
}
