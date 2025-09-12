//
//  CryptoAccountsPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountsPersistentStorage {
    func getList() -> [StoredCryptoAccount]
    func appendNewOrUpdateExisting(account: StoredCryptoAccount)
    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool)
    func removeAll()
}

// [REDACTED_TODO_COMMENT]
protocol _CryptoAccountsPersistentStorage {
    typealias StorageDidUpdateSubject = PassthroughSubject<Void, Never>

    func bind(to storageDidUpdateSubject: StorageDidUpdateSubject)
    func isMigrationNeeded() -> Bool
}
