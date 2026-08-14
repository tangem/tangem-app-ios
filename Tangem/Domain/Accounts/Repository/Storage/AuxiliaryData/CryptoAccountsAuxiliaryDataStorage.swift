//
//  CryptoAccountsAuxiliaryDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountsAuxiliaryDataStorage {
    var didChangePublisher: AnyPublisher<Void, Never> { get }
    var hasSyncedWithRemote: Bool { get nonmutating set }
    var archivedAccountsCount: Int { get nonmutating set }
    var totalCryptoAccountsCount: Int { get nonmutating set }
}

// MARK: - Convenience extensions

extension CryptoAccountsAuxiliaryDataStorage {
    func update(withArchivedAccountsCount archivedAccountsCount: Int, totalCryptoAccountsCount: Int) {
        self.archivedAccountsCount = archivedAccountsCount
        self.totalCryptoAccountsCount = totalCryptoAccountsCount
    }

    func update(withRemoteInfo remoteInfo: RemoteCryptoAccountsInfo) {
        update(withArchivedAccountsCount: remoteInfo.counters.archived, totalCryptoAccountsCount: remoteInfo.counters.crypto)
    }
}
