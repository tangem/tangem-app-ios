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
    @available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
    case wallets(cid: String)
    /// - Note: Supersedes `wallets(cid:)`.
    case accounts(cid: String)
    case walletConnectSessions
    case pendingExpressTransactions
    case pendingOnrampTransactions
    case pendingStakingTransactions
    case onrampPreference
    case tokenSearchQueryHistory
    case tokenSearchAssetHistory
    case addressBook(cid: String)

    var path: String {
        switch self {
        case .wallets(let cid):
            return "wallets_\(cid)"
        case .accounts(let cid):
            return "accounts_\(cid)"
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
        case .tokenSearchQueryHistory:
            return "token_search_query_history"
        case .tokenSearchAssetHistory:
            return "token_search_asset_history"
        case .addressBook(let cid):
            return "address_book_\(cid)"
        }
    }

    /// Should the file be protected while the device is locked? For sensitive data.
    var shouldEnableCompleteFileProtection: Bool {
        switch self {
        case .accounts:
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
        case .tokenSearchQueryHistory:
            false
        case .tokenSearchAssetHistory:
            false
        case .addressBook:
            false
        }
    }
}
