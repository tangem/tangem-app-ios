//
//  AppDatabaseConstraintTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

@Suite("AppDatabase constraints")
struct AppDatabaseConstraintTests {
    @Test("Upserting a crypto currency with the same composite key updates the existing row")
    func cryptoCurrencyUpsertUpdatesInsteadOfDuplicating() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try databaseQueue.write { database in
            try original.insert(database)
        }

        let updated = CryptoCurrencyRecord(
            id: "updated-token-id",
            networkID: original.networkID,
            name: "Updated Token",
            symbol: "TKN2",
            contractAddress: original.contractAddress,
            decimalCount: original.decimalCount,
            updatedAt: Date(timeIntervalSince1970: 1_752_003_600.5)
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

    @Test("Composite primary key treats contract addresses case-sensitively")
    func cryptoCurrencyPrimaryKeyIsCaseSensitive() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let caseVariant = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: original.networkID,
            contractAddress: original.contractAddress.lowercased()
        )

        try databaseQueue.write { database in
            try original.insert(database)
            try caseVariant.insert(database)
        }

        let rowCount = try databaseQueue.read { database in
            try CryptoCurrencyRecord.fetchCount(database)
        }

        #expect(rowCount == 2)
    }

    @Test("Upserting sync metadata with the same composite key updates the cursors")
    func syncMetadataUpsertUpdatesCursors() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "exchange")
        let updated = AppDatabaseFixtures.makeFullSyncMetadataRecord(
            ownerAddress: original.ownerAddress,
            endpointType: original.endpointType
        )

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

    @Test("Upserting a provider with the same id and type updates the existing row")
    func providerUpsertUpdatesInsteadOfDuplicating() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeMinimalProviderRecord(id: "changelly", type: "cex")
        let updated = AppDatabaseFixtures.makeFullProviderRecord(id: original.id, type: original.type)

        try databaseQueue.write { database in
            try original.insert(database)
            try updated.upsert(database)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try ExpressProviderRecord.fetchCount(database)
            let fetchedRecord = try ExpressProviderRecord.fetchOne(
                database,
                key: ["id": updated.id, "type": updated.type]
            )

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), updated)
    }

    /// The provider primary key is composite (id, type): the same provider id must be storable
    /// once per branch without conflicts.
    @Test("Providers with the same id but different types coexist")
    func providersWithSameIdButDifferentTypesCoexist() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let swapProvider = AppDatabaseFixtures.makeFullProviderRecord(id: "dual", type: "cex")
        let onrampProvider = AppDatabaseFixtures.makeFullProviderRecord(id: "dual", type: "onramp")

        try databaseQueue.write { database in
            try swapProvider.insert(database)
            try onrampProvider.insert(database)
        }

        let rowCount = try databaseQueue.read { database in
            try ExpressProviderRecord.fetchCount(database)
        }

        #expect(rowCount == 2)
    }

    @Test("Upserting a history index row with the same composite key updates the existing row")
    func historyIndexUpsertUpdatesInsteadOfDuplicating() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try original.insert(database)
        }

        let updated = TransactionHistoryIndexRecord(
            entityType: original.entityType,
            entityID: original.entityID,
            address: original.address,
            network: original.network,
            contract: original.contract,
            dateTime: Date(timeIntervalSince1970: 1_752_003_600.5)
        )

        try databaseQueue.write { database in
            try updated.upsert(database)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try TransactionHistoryIndexRecord.fetchCount(database)
            let fetchedRecord = try TransactionHistoryIndexRecord.fetchOne(
                database,
                key: [
                    "entityType": updated.entityType,
                    "entityID": updated.entityID,
                    "address": updated.address,
                    "network": updated.network,
                    "contract": updated.contract,
                ]
            )

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), updated)
    }

    @Test("History index rows for different legs of the same entity coexist")
    func historyIndexRowsForDifferentLegsCoexist() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let fromLeg = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xFrom",
            network: "ethereum",
            contract: AppDatabaseFixtures.mixedCaseContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let payOutLeg = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xPayOut",
            network: "bitcoin",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let refundLeg = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xRefund",
            network: "ethereum",
            contract: AppDatabaseFixtures.mixedCaseContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try fromLeg.insert(database)
            try payOutLeg.insert(database)
            try refundLeg.insert(database)
        }

        let rowCount = try databaseQueue.read { database in
            try TransactionHistoryIndexRecord.fetchCount(database)
        }

        #expect(rowCount == 3)
    }

    @Test("Inserting a duplicate history index row with the ignore policy keeps the original")
    func historyIndexInsertWithIgnorePolicyKeepsOriginal() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let original = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let duplicate = TransactionHistoryIndexRecord(
            entityType: original.entityType,
            entityID: original.entityID,
            address: original.address,
            network: original.network,
            contract: original.contract,
            dateTime: Date(timeIntervalSince1970: 1_752_003_600.5)
        )

        try databaseQueue.write { database in
            try original.insert(database)
            try duplicate.insert(database, onConflict: .ignore)
        }

        let result = try databaseQueue.read { database in
            let rowCount = try TransactionHistoryIndexRecord.fetchCount(database)
            let fetchedRecord = try TransactionHistoryIndexRecord.fetchOne(
                database,
                key: [
                    "entityType": original.entityType,
                    "entityID": original.entityID,
                    "address": original.address,
                    "network": original.network,
                    "contract": original.contract,
                ]
            )

            return (rowCount: rowCount, fetchedRecord: fetchedRecord)
        }

        #expect(result.rowCount == 1)
        try expectSameDatabaseRepresentation(try #require(result.fetchedRecord), original)
    }
}
