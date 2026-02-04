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
    func makeDefaultAccount(defaultTokensOverride: [StoredCryptoAccount.Token]) -> StoredCryptoAccount

    /// Returns an existing default account if found, otherwise creates a new one.
    /// Used for wallets with sync support, which can be onboarded offline and sync later.
    func makeDefaultAccountPreferringExisting(defaultTokensOverride: [StoredCryptoAccount.Token]) -> StoredCryptoAccount
}
