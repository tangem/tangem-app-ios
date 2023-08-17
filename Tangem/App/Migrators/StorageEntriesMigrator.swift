//
//  StorageEntriesMigrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import func QuartzCore.CACurrentMediaTime

final class StorageEntriesMigrator {
    typealias V3EntriesHandler = (_ entries: [StorageEntry.V3.Entry], _ cardID: String) -> Void

    private let persistanceStorage: PersistentStorageProtocol
    private let cardID: String
    private let v3EntriesHandler: V3EntriesHandler

    init(
        persistanceStorage: PersistentStorageProtocol,
        cardID: String,
        v3EntriesHandler: @escaping V3EntriesHandler
    ) {
        self.persistanceStorage = persistanceStorage
        self.cardID = cardID
        self.v3EntriesHandler = v3EntriesHandler
    }

    // MARK: - Common

    func migrate(
        from reportedCurrentStorageVersion: StorageEntry.Version,
        to actualVersion: StorageEntry.Version
    ) {
        let currentStorageVersion = getCurrentStorageVersion(reportedCurrentStorageVersion)
        let migrationStartTime = CACurrentMediaTime()

        migrateIfNeeded(from: currentStorageVersion, to: actualVersion, migrationStartTime: migrationStartTime)
    }

    private func getCurrentStorageVersion(
        _ currentStorageVersionSinceV3: StorageEntry.Version
    ) -> StorageEntry.Version {
        // Storage versioning was introduced in v3, so we have to apply some heuristic for v1/v2 versions
        if getV1StorageEntries() != nil {
            return .v1
        }

        if getV2StorageEntries() != nil {
            return .v2
        }

        return currentStorageVersionSinceV3
    }

    private func migrateIfNeeded(
        from oldVersion: StorageEntry.Version,
        to newVersion: StorageEntry.Version,
        migrationStartTime: CFTimeInterval
    ) {
        let result: StorageMigrationResult

        switch oldVersion {
        case .v1:
            result = migrateV1StorageEntriesIfNeeded()
        case .v2:
            result = migrateV2StorageEntriesIfNeeded()
        case .v3:
            result = migrateV3StorageEntriesIfNeeded()
        }

        if result.wasMigrated {
            let migrationDuration = String(format: "took %.5fs", CACurrentMediaTime() - migrationStartTime)

            AppLog.shared.debug(
                """
                \(objectDescription(self)): successfully performed storage migration for cardID \
                \(cardID) from version \(oldVersion.rawValue) to \(newVersion.rawValue) \
                (coins: \(result.coinsCount), tokens: \(result.tokensCount), \(migrationDuration))
                """
            )
        } else {
            AppLog.shared.debug(
                """
                \(objectDescription(self)): storage migration for cardID \(cardID) from version \
                \(oldVersion.rawValue) to \(newVersion.rawValue) was requested, but not performed
                """
            )
        }
    }

    // MARK: - V1 specific

    private func migrateV1StorageEntriesIfNeeded() -> StorageMigrationResult {
        var result = StorageMigrationResult()

        guard let v1Wallets = getV1StorageEntries() else { return result }

        v1Wallets.forEach { cardId, v1StorageEntries in
            let blockchains = Set(v1StorageEntries.map { $0.blockchain })
            let tokens = v1StorageEntries.compactMap { $0.token }
            let groupedTokens = Dictionary(grouping: tokens, by: { $0.blockchain })

            let v2StorageEntries: [StorageEntry.V2.Entry] = blockchains.map { blockchain in
                let tokens = groupedTokens[blockchain]?.map { $0.newToken } ?? []
                let network = BlockchainNetwork(
                    blockchain,
                    derivationPath: blockchain.derivationPath(for: .v1)
                )
                return StorageEntry.V2.Entry(blockchainNetwork: network, tokens: tokens)
            }

            // All v2 storage entries from each wallet are going to be migrated to v3
            let walletMigrationResult = migrateV2StorageEntries(v2StorageEntries, forCardID: cardId)

            if walletMigrationResult.wasMigrated {
                result.wasMigrated = true
                result.coinsCount += walletMigrationResult.coinsCount
                result.tokensCount += walletMigrationResult.tokensCount
            }
        }

        return result
    }

    private func getV1StorageEntries() -> [String: [StorageEntry.V1.Entry]]? {
        return persistanceStorage.readAllWallets().nilIfEmpty
    }

    // MARK: - V2 specific

    private func migrateV2StorageEntriesIfNeeded() -> StorageMigrationResult {
        guard let storageEntries = getV2StorageEntries() else { return StorageMigrationResult() }

        return migrateV2StorageEntries(storageEntries, forCardID: cardID)
    }

    private func migrateV2StorageEntries(
        _ v2StorageEntries: [StorageEntry.V2.Entry],
        forCardID cardID: String
    ) -> StorageMigrationResult {
        var result = StorageMigrationResult()
        let converter = StorageEntriesConverter()
        let v3StorageEntries: [StorageEntry.V3.Entry] = v2StorageEntries
            .reduce(into: []) { partialResult, element in
                let blockchainNetwork = element.blockchainNetwork

                partialResult.append(converter.convert(blockchainNetwork))
                partialResult += element.tokens.map { converter.convert($0, in: blockchainNetwork) }

                result.wasMigrated = true
                result.coinsCount += 1
                result.tokensCount += element.tokens.count
            }

        v3EntriesHandler(v3StorageEntries, cardID)

        return result
    }

    private func getV2StorageEntries() -> [StorageEntry.V2.Entry]? {
        let storageEntries: [StorageEntry.V2.Entry]? = try? persistanceStorage.value(for: .wallets(cid: cardID))

        return storageEntries?.nilIfEmpty
    }

    // MARK: - V3 specific

    private func migrateV3StorageEntriesIfNeeded() -> StorageMigrationResult {
        // No-op, actual version at the moment
        return StorageMigrationResult()
    }
}

// MARK: - Auxiliary types

private extension StorageEntriesMigrator {
    struct StorageMigrationResult {
        var wasMigrated = false
        var coinsCount = 0
        var tokensCount = 0
    }
}
