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
    func appendNewOrUpdateExisting(accounts: [StoredCryptoAccount])
    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool)
}

// MARK: - Convenience extensions

extension CryptoAccountsPersistentStorage {
    func appendNewOrUpdateExisting(account: StoredCryptoAccount) {
        appendNewOrUpdateExisting(accounts: [account])
    }

    func removeAll() {
        removeAll { _ in true }
    }
}
