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
    /// Joint accounts are stored apart from `accounts(cid:)` – they come from their own endpoint
    case jointAccounts(cid: String)
    /// Invites are stored apart from `jointAccounts(cid:)` – the endpoint hands them out once and never reports them
    /// again, so a list read replacing what it knows must not be able to take them along
    case jointAccountInvites(cid: String)
    /// The unfinished operations ride inside the accounts on the wire but are stored apart from `jointAccounts(cid:)`
    /// – a co-signer answering or the relayer executing is no change to the account itself
    case jointAccountPendingOperations(cid: String)
    case walletConnectSessions
    case pendingExpressTransactions
    case pendingOnrampTransactions
    case onrampUnknownStatuses
    case walletCardsBackupReports
    case pendingStakingTransactions
    case onrampPreference
    case addressBook(cid: String)
    case coinsCategoriesCache
    case coinsGeckoCategoriesCache
    case tangemPayRecentOperations(cid: String)
    case polymarketWithdrawRecord(cid: String)

    var path: String {
        switch self {
        case .wallets(let cid):
            return "wallets_\(cid)"
        case .accounts(let cid):
            return "accounts_\(cid)"
        case .jointAccounts(let cid):
            return "joint_accounts_\(cid)"
        case .jointAccountInvites(let cid):
            return "joint_account_invites_\(cid)"
        case .jointAccountPendingOperations(let cid):
            return "joint_account_pending_operations_\(cid)"
        case .walletConnectSessions:
            return "wallet_connect_sessions"
        case .pendingExpressTransactions:
            return "express_pending_transactions"
        case .pendingOnrampTransactions:
            return "onramp_pending_transactions"
        case .onrampUnknownStatuses:
            return "onramp_unknown_statuses"
        case .walletCardsBackupReports:
            return "wallet_cards_backup_reports"
        case .pendingStakingTransactions:
            return "staking_pending_transactions"
        case .onrampPreference:
            return "onramp_preference"
        case .addressBook(let cid):
            return "address_book_\(cid)"
        case .coinsCategoriesCache:
            return "coins_categories_cache"
        case .coinsGeckoCategoriesCache:
            return "coins_gecko_categories_cache"
        case .tangemPayRecentOperations(let cid):
            return "tangem_pay_recent_operations_\(cid)"
        case .polymarketWithdrawRecord(let cid):
            return "polymarket_withdraw_record_\(cid)"
        }
    }

    /// Should the file be protected while the device is locked? For sensitive data.
    var shouldEnableCompleteFileProtection: Bool {
        switch self {
        case .accounts:
            false
        case .jointAccounts:
            // Holds the names and addresses of the other members, but the blob is encrypted like every other
            // per-wallet cache, and the accounts list has to be readable while the device is locked
            false
        case .jointAccountInvites:
            // Holds the accounts' access secrets, but the blob is encrypted on saving like every other per-wallet
            // cache, which is the protection this storage is built on
            false
        case .jointAccountPendingOperations:
            // Holds the destinations and amounts the members are signing, nothing that spends; the blob is encrypted
            // like every other per-wallet cache, and the accounts list has to be readable while the device is locked
            false
        case .onrampPreference:
            false
        case .pendingExpressTransactions:
            false
        case .pendingOnrampTransactions:
            false
        case .onrampUnknownStatuses:
            false
        case .walletCardsBackupReports:
            false
        case .pendingStakingTransactions:
            false
        case .walletConnectSessions:
            false
        case .wallets:
            false
        case .addressBook:
            // The cached blob is already AES-256-GCM encrypted, so it matches the convention of the
            // other per-wallet caches (e.g. accounts) rather than enabling complete file protection.
            false
        case .coinsCategoriesCache, .coinsGeckoCategoriesCache:
            // Public market metadata, and the shelf has to render while the device is locked.
            false
        case .tangemPayRecentOperations:
            false
        case .polymarketWithdrawRecord:
            // Holds only the backend's id of the withdrawal, its state and a public Polygon hash, and the blob is
            // encrypted like every other per-wallet cache. The status poller may land an answer right as the
            // device locks, and complete protection would turn that write into a lost CONFIRMED or FAILED.
            false
        }
    }
}
