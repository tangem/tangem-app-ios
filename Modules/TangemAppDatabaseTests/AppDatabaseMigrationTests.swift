//
//  AppDatabaseMigrationTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

@Suite("AppDatabase data migrations")
struct AppDatabaseMigrationTests {
    @Test("V3 rekeys sync metadata by the migrated wallet ID and keeps the other columns intact")
    func v3RekeysSyncMetadataByMigratedWalletID() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue(upTo: .v2)
        let legacyRecords = [
            Self.makeV2SyncMetadataRecord(
                userWalletID: "AA01",
                endpointType: "swap",
                archiveCursor: "archive-cursor-1",
                deltaCursor: "delta-cursor-1",
                isInitialSyncDone: true
            ),
            Self.makeV2SyncMetadataRecord(
                userWalletID: "AA01",
                endpointType: "onramp",
                archiveCursor: nil,
                deltaCursor: "delta-cursor-2",
                isInitialSyncDone: true
            ),
            Self.makeV2SyncMetadataRecord(
                userWalletID: "BB02",
                endpointType: "swap",
                archiveCursor: "archive-cursor-3",
                deltaCursor: nil,
                isInitialSyncDone: false
            ),
        ]

        try databaseQueue.write { database in
            for legacyRecord in legacyRecords {
                try legacyRecord.insert(database)
            }
        }

        try AppDatabase
            .makeDatabaseMigrator(migrationHelper: AppDatabaseMigrationHelperStub.prefixing)
            .migrate(databaseQueue)

        let migratedRecords = try databaseQueue.read { database in
            try ExpressSyncMetadataRecord.fetchAll(database)
        }
        let expectedRecords = legacyRecords.map { legacyRecord in
            ExpressSyncMetadataRecord(
                walletID: "migrated-\(legacyRecord.userWalletID)",
                endpointType: legacyRecord.endpointType,
                archiveCursor: legacyRecord.archiveCursor,
                deltaCursor: legacyRecord.deltaCursor,
                isInitialSyncDone: legacyRecord.isInitialSyncDone,
                lastSyncAt: legacyRecord.lastSyncAt
            )
        }

        let migratedRepresentations = try Set(migratedRecords.map { try $0.databaseDictionary })
        let expectedRepresentations = try Set(expectedRecords.map { try $0.databaseDictionary })

        #expect(migratedRecords.count == legacyRecords.count)
        #expect(migratedRepresentations == expectedRepresentations)
    }

    @Test("V3 doesn't fail when several stored values are migrated into the same value")
    func v3ToleratesHashCollisions() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue(upTo: .v2)
        let migrationHelper = AppDatabaseMigrationHelperStub { walletID in
            return walletID.hasPrefix("0x") ? "collision" : "migrated-\(walletID)"
        }

        try databaseQueue.write { database in
            for userWalletID in ["0xLegacyAddress1", "0xLegacyAddress2", "CC03"] {
                try Self.makeV2SyncMetadataRecord(
                    userWalletID: userWalletID,
                    endpointType: "swap",
                    archiveCursor: nil,
                    deltaCursor: nil,
                    isInitialSyncDone: false
                ).insert(database)
            }
        }

        try AppDatabase
            .makeDatabaseMigrator(migrationHelper: migrationHelper)
            .migrate(databaseQueue)

        let walletIDs = try databaseQueue.read { database in
            try ExpressSyncMetadataRecord
                .order { $0.walletID }
                .select({ $0.walletID }, as: String.self)
                .fetchAll(database)
        }

        #expect(walletIDs == ["collision", "migrated-CC03"])
    }
}

// MARK: - Factory methods

private extension AppDatabaseMigrationTests {
    static func makeV2SyncMetadataRecord(
        userWalletID: String,
        endpointType: String,
        archiveCursor: String?,
        deltaCursor: String?,
        isInitialSyncDone: Bool
    ) -> V2SyncMetadataRecord {
        V2SyncMetadataRecord(
            userWalletID: userWalletID,
            endpointType: endpointType,
            archiveCursor: archiveCursor,
            deltaCursor: deltaCursor,
            isInitialSyncDone: isInitialSyncDone,
            lastSyncAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }
}

// MARK: - Auxiliary types

private extension AppDatabaseMigrationTests {
    struct V2SyncMetadataRecord: Codable, PersistableRecord {
        static let databaseTableName = "expressSyncMetadata"

        let userWalletID: String
        let endpointType: String
        let archiveCursor: String?
        let deltaCursor: String?
        let isInitialSyncDone: Bool
        let lastSyncAt: Date
    }
}
