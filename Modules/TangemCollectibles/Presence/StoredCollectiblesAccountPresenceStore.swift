//
//  StoredCollectiblesAccountPresenceStore.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import TangemFoundation

public struct StoredCollectiblesAccountPresenceStore {
    private let storage: any CollectiblesPresenceStorage
    private let hashSalt: String

    /// - Parameter hashSalt: the storage key the flag is written under, which also salts the hashed wallet id.
    public init(storage: any CollectiblesPresenceStorage, hashSalt: String) {
        self.storage = storage
        self.hashSalt = hashSalt
    }
}

// MARK: - CollectiblesAccountPresenceStore protocol conformance

extension StoredCollectiblesAccountPresenceStore: CollectiblesAccountPresenceStore {
    public func contains(_ userWalletId: UserWalletId) -> Bool {
        storage.collectiblesHasAccount[key(for: userWalletId), default: false]
    }

    public func insert(_ userWalletId: UserWalletId) {
        guard !contains(userWalletId) else {
            return
        }

        storage.collectiblesHasAccount[key(for: userWalletId)] = true
    }

    public func remove(_ userWalletId: UserWalletId) {
        guard contains(userWalletId) else {
            return
        }

        storage.collectiblesHasAccount[key(for: userWalletId)] = nil
    }
}

// MARK: - Private implementation

private extension StoredCollectiblesAccountPresenceStore {
    /// The wallet id is private, so the storage holds a hash of it rather than the id itself.
    func key(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: hashSalt)
    }
}
