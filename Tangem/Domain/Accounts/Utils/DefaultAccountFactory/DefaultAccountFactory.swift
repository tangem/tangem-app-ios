//
//  DefaultAccountFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol DefaultAccountFactory {
    /// Creates a new default account. Used for wallets without sync support.
    /// - Note: `defaultTokensOverride` is an optional archive, pass `nil` to prevent default tokens from being overridden,
    /// pass empty array to override default tokens with an empty tokens list.
    func makeDefaultAccount(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount

    /// Returns an existing default account if found, otherwise creates a new one.
    /// Used for wallets with sync support, which can be onboarded offline and sync later.
    /// - Note: `defaultTokensOverride` is an optional archive, pass `nil` to prevent default tokens from being overridden,
    /// pass empty array to override default tokens with an empty tokens list.
    func makeDefaultAccountPreferringExisting(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount
}
