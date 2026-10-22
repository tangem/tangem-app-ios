//
//  JointAccountsInvitesPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// - Note: Separate from `JointAccountsPersistentStorage` because the endpoint reports an account's invites once, when
/// it is created, and never again: what a list read brings back must not be able to overwrite them.
protocol JointAccountsInvitesPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }

    /// - Warning: May block the calling thread while the underlying storage is read from disk.
    /// Avoid calling from the main thread directly.
    func getList() -> [StoredJointAccountInvites]

    /// - Warning: The invites of an account are written as a whole, since they are handed out as a whole.
    func save(_ invites: [StoredJointAccountInvite], forCryptoAccountId cryptoAccountId: String) throws
}
