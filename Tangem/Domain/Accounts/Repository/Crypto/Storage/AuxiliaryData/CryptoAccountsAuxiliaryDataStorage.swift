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
    var totalJointAccountsCount: Int { get nonmutating set }
}

// MARK: - Convenience extensions

extension CryptoAccountsAuxiliaryDataStorage {
    func update(
        withArchivedAccountsCount archivedAccountsCount: Int,
        totalCryptoAccountsCount: Int,
        totalJointAccountsCount: Int
    ) {
        self.archivedAccountsCount = archivedAccountsCount
        self.totalCryptoAccountsCount = totalCryptoAccountsCount
        self.totalJointAccountsCount = totalJointAccountsCount
    }

    /// - Note: An uncounted joint kind stands for none: an endpoint that does not count the kinds apart is one
    /// where a joint account cannot exist in the first place.
    func update(withRemoteInfo remoteInfo: RemoteCryptoAccountsInfo) {
        update(
            withArchivedAccountsCount: remoteInfo.counters.archived,
            totalCryptoAccountsCount: remoteInfo.counters.crypto,
            totalJointAccountsCount: remoteInfo.counters.joint ?? 0
        )
    }
}
