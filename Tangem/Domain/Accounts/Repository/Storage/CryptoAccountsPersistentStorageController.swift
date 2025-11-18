//
//  CryptoAccountsPersistentStorageController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// A helper interface for `CryptoAccountsPersistentStorage` to handle migrations and notify about storage updates.
protocol CryptoAccountsPersistentStorageController {
    typealias StorageDidUpdateSubject = PassthroughSubject<Void, Never>

    func bind(to storageDidUpdateSubject: StorageDidUpdateSubject)
    func isMigrationNeeded() -> Bool
}
