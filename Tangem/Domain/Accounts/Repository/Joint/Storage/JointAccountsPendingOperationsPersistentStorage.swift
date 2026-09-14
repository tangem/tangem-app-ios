//
//  JointAccountsPendingOperationsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// - Note: Separate from `JointAccountsPersistentStorage` because an operation moves on its own occasions — a
/// co-signer answers, the relayer executes — and none of them is a change to the account it belongs to.
protocol JointAccountsPendingOperationsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }

    /// - Warning: May block the calling thread while the underlying storage is read from disk.
    /// Avoid calling from the main thread directly.
    func getList() -> [StoredJointAccountPendingOperations]

    /// - Note: Every account's operations at once, the way the listing reports them: an account gone from the
    /// listing, or one with nothing in flight any more, is gone from here too.
    func replace(with records: [StoredJointAccountPendingOperations]) throws
}
