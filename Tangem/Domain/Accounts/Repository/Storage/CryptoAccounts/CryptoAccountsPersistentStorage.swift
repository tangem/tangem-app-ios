//
//  CryptoAccountsPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CryptoAccountsPersistentStorage {
    func getList() -> [StoredCryptoAccount]
    func appendNewOrUpdateExisting(_ accounts: [StoredCryptoAccount])
    func replace(with accounts: [StoredCryptoAccount])
    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool)
}

// MARK: - Convenience extensions

extension CryptoAccountsPersistentStorage {
    func appendNewOrUpdateExisting(_ account: StoredCryptoAccount) {
        appendNewOrUpdateExisting([account])
    }

    func removeAll() {
        removeAll { _ in true }
    }

    func replace(with accounts: [StoredCryptoAccount]) {
        removeAll()
        appendNewOrUpdateExisting(accounts)
    }
}
