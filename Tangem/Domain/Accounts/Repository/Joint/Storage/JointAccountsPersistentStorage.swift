//
//  JointAccountsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol JointAccountsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }

    /// - Warning: May block the calling thread while the underlying storage is read from disk.
    /// Avoid calling from the main thread directly.
    func getList() -> [StoredJointAccount]

    func appendNewOrUpdateExisting(_ account: StoredJointAccount) throws

    func replace(with accounts: [StoredJointAccount]) throws
}
