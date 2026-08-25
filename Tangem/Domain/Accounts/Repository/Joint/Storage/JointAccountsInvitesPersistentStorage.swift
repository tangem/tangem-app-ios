//
//  JointAccountsInvitesPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// - Note: Separate from `JointAccountsPersistentStorage` because the endpoint reports an account's invites once, when
/// it is created, and never again: what a list read brings back must not be able to overwrite them.
protocol JointAccountsInvitesPersistentStorage {
    /// - Returns: `nil` when nothing was ever written for the account, which is not the same as an account created
    /// with no free slots — that one has an empty list of its own.
    /// - Warning: May block the calling thread while the underlying storage is read from disk.
    /// Avoid calling from the main thread directly.
    func getInvites(forCryptoAccountId cryptoAccountId: String) -> [JointAccountInvite]?

    /// - Warning: The invites of an account are written as a whole, since they are handed out as a whole.
    func save(_ invites: [JointAccountInvite], forCryptoAccountId cryptoAccountId: String) throws
}
