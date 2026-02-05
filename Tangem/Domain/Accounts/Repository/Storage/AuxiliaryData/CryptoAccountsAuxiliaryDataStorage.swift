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
    var archivedAccountsCount: Int { get nonmutating set }
    var totalAccountsCount: Int { get nonmutating set }
}

// MARK: - Convenience extensions

extension CryptoAccountsAuxiliaryDataStorage {
    func update(withArchivedAccountsCount archivedAccountsCount: Int, totalAccountsCount: Int) {
        self.archivedAccountsCount = archivedAccountsCount
        self.totalAccountsCount = totalAccountsCount
    }

    func update(withRemoteInfo remoteInfo: RemoteCryptoAccountsInfo) {
        update(withArchivedAccountsCount: remoteInfo.counters.archived, totalAccountsCount: remoteInfo.counters.total)
    }
}
