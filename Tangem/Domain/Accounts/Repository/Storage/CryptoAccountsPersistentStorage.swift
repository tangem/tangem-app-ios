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
    func appendNewOrUpdateExisting(account: StoredCryptoAccount)
    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool)
    func removeAll()
}
