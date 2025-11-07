//
//  CommonCryptoAccountsAuxiliaryDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonCryptoAccountsAuxiliaryDataStorage {
    private typealias Storage = AppStorageCompat<Key, Int>

    @Storage private var innerArchivedAccountsCount: Int {
        didSet {
            if oldValue != innerArchivedAccountsCount {
                didChangeSubject.send()
            }
        }
    }

    @Storage private var innerTotalAccountsCount: Int {
        didSet {
            if oldValue != innerTotalAccountsCount {
                didChangeSubject.send()
            }
        }
    }

    private let didChangeSubject = PassthroughSubject<Void, Never>()

    init(
        storageIdentifier: String
    ) {
        _innerArchivedAccountsCount = .init(wrappedValue: 0, .init(forArchivedAccountsCountWithWithStorageIdentifier: storageIdentifier))
        _innerTotalAccountsCount = .init(wrappedValue: 0, .init(forTotalAccountsCountWithStorageIdentifier: storageIdentifier))
    }
}

// MARK: - CryptoAccountsAuxiliaryDataStorage protocol conformance

extension CommonCryptoAccountsAuxiliaryDataStorage: CryptoAccountsAuxiliaryDataStorage {
    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject
            .prepend(())
            .eraseToAnyPublisher()
    }

    var archivedAccountsCount: Int {
        get { innerArchivedAccountsCount }
        set { innerArchivedAccountsCount = newValue }
    }

    var totalAccountsCount: Int {
        get { innerTotalAccountsCount }
        set { innerTotalAccountsCount = newValue }
    }
}

// MARK: - Auxiliary types

private struct Key: RawRepresentable {
    let rawValue: String

    init(forArchivedAccountsCountWithWithStorageIdentifier storageIdentifier: String) {
        rawValue = "CommonCryptoAccountsAuxiliaryDataStorage_archivedAccountsCount_\(storageIdentifier)"
    }

    init(forTotalAccountsCountWithStorageIdentifier storageIdentifier: String) {
        rawValue = "CommonCryptoAccountsAuxiliaryDataStorage_totalAccountsCount_\(storageIdentifier)"
    }

    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}
