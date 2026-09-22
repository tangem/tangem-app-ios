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

    func appendNewOrUpdateExisting(_ operation: JointAccountOperation, forCryptoAccountId cryptoAccountId: String) throws

    /// - Note: An account left with no operations keeps no record, the way a listing reporting none writes none.
    func remove(operationWithId operationId: String, forCryptoAccountId cryptoAccountId: String) throws
}
