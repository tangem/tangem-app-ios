//
//  AppDatabaseConstraintTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import Tangem

/// Pins the conflict semantics repository logic will rely on, independent of whether it ends up
/// using `upsert()` or `save()`.
@Suite("AppDatabase constraints", .tags(.appDatabase))
struct AppDatabaseConstraintTests {
    @Test("Upserting a crypto currency with the same composite key updates the existing row")
    func cryptoCurrencyUpsertUpdatesInsteadOfDuplicating() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeFullCryptoCurrencyRecord()

        try databaseQueue.write { database in
            try original.insert(database)
        }

        let updated = CryptoCurrencyRecord(
            id: "usd-coin-bridged",
            networkID: original.networkID,
            name: "Bridged USD Coin",
            symbol: "USDC.E",
            contractAddress: original.contractAddress,
            decimalCount: original.decimalCount,
            updatedAt: AppDatabaseFixtures.makeDate(secondsSince1970: 1_752_003_600.5)
        )

        try databaseQueue.write { database in
            try updated.upsert(database)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try CryptoCurrencyRecord.fetchCount(database)
            let fetchedRecord = try CryptoCurrencyRecord.fetchOne(
                database,
                key: ["networkID": updated.networkID, "contractAddress": updated.contractAddress]
            )

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), updated)
    }

    @Test("Composite primary key treats contract addresses case-insensitively")
    func cryptoCurrencyPrimaryKeyIsCaseInsensitive() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeFullCryptoCurrencyRecord()
        let caseVariant = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            contractAddress: original.contractAddress.lowercased()
        )

        try databaseQueue.write { database in
            try original.insert(database)
        }

        #expect(throws: DatabaseError.self) {
            try databaseQueue.write { database in
                try caseVariant.insert(database)
            }
        }

        try databaseQueue.write { database in
            try caseVariant.upsert(database)
        }

        let rowCount = try databaseQueue.read { database in
            try CryptoCurrencyRecord.fetchCount(database)
        }

        #expect(rowCount == 1)
    }

    @Test("Upserting sync metadata with the same composite key updates the cursors")
    func syncMetadataUpsertUpdatesCursors() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeMinimalSyncMetadataRecord()
        let updated = AppDatabaseFixtures.makeFullSyncMetadataRecord()

        try databaseQueue.write { database in
            try original.insert(database)
            try updated.upsert(database)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try ExpressSyncMetadataRecord.fetchCount(database)
            let fetchedRecord = try ExpressSyncMetadataRecord.fetchOne(
                database,
                key: ["ownerAddress": updated.ownerAddress, "endpointType": updated.endpointType]
            )

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), updated)
    }

    @Test("Upserting a provider with the same id updates the existing row")
    func providerUpsertUpdatesInsteadOfDuplicating() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeMinimalProviderRecord()
        let updated = AppDatabaseFixtures.makeFullProviderRecord()

        try databaseQueue.write { database in
            try original.insert(database)
            try updated.upsert(database)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try ExpressProviderRecord.fetchCount(database)
            let fetchedRecord = try ExpressProviderRecord.fetchOne(database, key: updated.id)

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), updated)
    }
}
