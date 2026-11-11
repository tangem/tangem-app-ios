//
//  JointAccountSafeAddressResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol JointAccountSafeAddressResolver {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }
    var accountSafes: [JointAccountSafe] { get }
}

struct CommonJointAccountSafeAddressResolver {
    private let persistentStorage: JointAccountsPersistentStorage

    init(persistentStorage: JointAccountsPersistentStorage) {
        self.persistentStorage = persistentStorage
    }
}

// MARK: - JointAccountSafeAddressResolver protocol conformance

extension CommonJointAccountSafeAddressResolver: JointAccountSafeAddressResolver {
    var didUpdatePublisher: AnyPublisher<Void, Never> {
        persistentStorage.didUpdatePublisher
    }

    var accountSafes: [JointAccountSafe] {
        persistentStorage.getList().compactMap { account in
            JointAccountSafe(cryptoAccountId: account.cryptoAccountId, status: account.status)
        }
    }
}
