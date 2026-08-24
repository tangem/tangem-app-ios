//
//  AppDatabaseSchemaTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

@Suite("AppDatabase schema")
struct AppDatabaseSchemaTests {
    /// The single most important test of the persistence layer: frozen schema versions must stay
    /// frozen. Any edit to already shipped DDL — a reordered primary key, a dropped index,
    /// a collation change — must show up as a deliberate diff of this fixture in review,
    /// never as an accidental drive-by change.
    @Test("Fresh database schema matches the pinned snapshot")
    func schemaMatchesSnapshot() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let schema = try databaseQueue.read { database in
            try String.fetchAll(database, sql: "SELECT sql FROM sqlite_schema WHERE sql IS NOT NULL ORDER BY name")
        }
        .joined(separator: "\n\n")

        #expect(schema == Self.expectedSchemaV1)
    }

    @Test("Applied migration identifiers are pinned")
    func appliedMigrationIdentifiersArePinned() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let identifiers = try databaseQueue.read { database in
            try String.fetchAll(database, sql: "SELECT identifier FROM grdb_migrations ORDER BY identifier")
        }

        #expect(identifiers == ["v1"])
    }

    @Test("Database version identifiers are unique")
    func versionIdentifiersAreUnique() {
        let identifiers = AppDatabaseVersion.allCases.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("History index entity type literals are pinned")
    func historyIndexEntityTypeLiteralsArePinned() {
        #expect(TransactionHistoryIndexRecord.Values.EntityType.expressExchange == "expressExchange")
        #expect(TransactionHistoryIndexRecord.Values.EntityType.expressOnramp == "expressOnramp")
    }

    /// Tests run in DEBUG, where `eraseDatabaseOnSchemaChange` is enabled: data surviving
    /// a second migration run proves the registered schema is deterministic, i.e. the app
    /// won't wipe the database on every launch.
    @Test("Re-migrating an already migrated database is a lossless no-op")
    func remigrationPreservesData() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let record = AppDatabaseFixtures.makeFullFiatCurrencyRecord()

        try databaseQueue.write { database in
            try record.insert(database)
        }

        let remigratedAppDatabase = AppDatabase { _ in databaseQueue }
        _ = try remigratedAppDatabase.databaseHandle

        let fetchedRecord = try databaseQueue.read { database in
            try FiatCurrencyRecord.fetchOne(database, key: record.code)
        }

        try expectSameDatabaseRepresentation(try #require(fetchedRecord), record)
    }
}

// MARK: - Fixtures

private extension AppDatabaseSchemaTests {
    static let expectedSchemaV1 = """
    CREATE TABLE "cryptoCurrenciesCache" ("id" TEXT, "networkID" TEXT NOT NULL, "name" TEXT NOT NULL, "symbol" TEXT NOT NULL, "contractAddress" TEXT NOT NULL, "decimalCount" INTEGER NOT NULL, "updatedAt" DATETIME NOT NULL, PRIMARY KEY ("networkID", "contractAddress"))

    CREATE TABLE "expressExchangeTransactions" ("id" TEXT PRIMARY KEY NOT NULL, "ownerAddress" TEXT NOT NULL, "providerID" TEXT NOT NULL, "fromAddress" TEXT, "payInAddress" TEXT NOT NULL, "payInExtraId" TEXT, "payOutAddress" TEXT NOT NULL, "status" TEXT NOT NULL, "rateType" TEXT, "externalTxID" TEXT, "externalTxURL" TEXT, "payInHash" TEXT, "payOutHash" TEXT, "fromNetwork" TEXT NOT NULL, "fromContract" TEXT NOT NULL, "fromAmount" TEXT NOT NULL, "fromDecimals" INTEGER NOT NULL, "fromActualAmount" TEXT, "toNetwork" TEXT NOT NULL, "toContract" TEXT NOT NULL, "toAmount" TEXT NOT NULL, "toDecimals" INTEGER NOT NULL, "toActualAmount" TEXT, "refundAddress" TEXT, "refundExtraId" TEXT, "refundNetwork" TEXT, "refundContractAddress" TEXT, "createdAt" DATETIME NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE "expressOnrampTransactions" ("id" TEXT PRIMARY KEY NOT NULL, "ownerAddress" TEXT NOT NULL, "providerID" TEXT NOT NULL, "payOutAddress" TEXT NOT NULL, "status" TEXT NOT NULL, "externalTxID" TEXT, "externalTxURL" TEXT, "payOutHash" TEXT, "fromCurrency" TEXT NOT NULL, "fromAmount" TEXT NOT NULL, "toContract" TEXT NOT NULL, "toNetwork" TEXT NOT NULL, "toAmount" TEXT, "toDecimals" INTEGER NOT NULL, "toActualAmount" TEXT, "failReason" TEXT, "paymentMethod" TEXT NOT NULL, "countryCode" TEXT NOT NULL, "createdAt" DATETIME NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE "expressProvidersCache" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "exchangeOnlyWithinSingleAddress" BOOLEAN NOT NULL, "imageURL" TEXT, "termsOfUse" TEXT, "privacyPolicy" TEXT, "recommended" BOOLEAN, "slippage" TEXT, "updatedAt" DATETIME NOT NULL, PRIMARY KEY ("id", "type"))

    CREATE TABLE "expressSyncMetadata" ("ownerAddress" TEXT NOT NULL, "endpointType" TEXT NOT NULL, "archiveCursor" TEXT, "deltaCursor" TEXT, "isInitialSyncDone" BOOLEAN NOT NULL DEFAULT 0, "lastSyncAt" DATETIME NOT NULL, PRIMARY KEY ("ownerAddress", "endpointType"))

    CREATE TABLE "fiatCurrenciesCache" ("code" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "imageURL" TEXT, "precision" INTEGER NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE grdb_migrations (identifier TEXT NOT NULL PRIMARY KEY)

    CREATE INDEX "index_cryptoCurrenciesCache_on_id" ON "cryptoCurrenciesCache"("id")

    CREATE INDEX "index_expressExchangeTransactions_on_fromNetwork_fromContract_ownerAddress" ON "expressExchangeTransactions"("fromNetwork", "fromContract", "ownerAddress")

    CREATE INDEX "index_expressExchangeTransactions_on_ownerAddress" ON "expressExchangeTransactions"("ownerAddress")

    CREATE INDEX "index_expressExchangeTransactions_on_payInHash" ON "expressExchangeTransactions"("payInHash")

    CREATE INDEX "index_expressExchangeTransactions_on_payOutHash" ON "expressExchangeTransactions"("payOutHash")

    CREATE INDEX "index_expressExchangeTransactions_on_status_refundNetwork_refundContractAddress_refundAddress_createdAt" ON "expressExchangeTransactions"("status", "refundNetwork", "refundContractAddress", "refundAddress", "createdAt")

    CREATE INDEX "index_expressExchangeTransactions_on_toNetwork_toContract_ownerAddress" ON "expressExchangeTransactions"("toNetwork", "toContract", "ownerAddress")

    CREATE INDEX "index_expressOnrampTransactions_on_ownerAddress" ON "expressOnrampTransactions"("ownerAddress")

    CREATE INDEX "index_expressOnrampTransactions_on_payOutHash" ON "expressOnrampTransactions"("payOutHash")

    CREATE INDEX "index_expressOnrampTransactions_on_toNetwork_toContract_ownerAddress" ON "expressOnrampTransactions"("toNetwork", "toContract", "ownerAddress")

    CREATE INDEX "index_transactionHistoryIndex_on_address_network_contract_dateTime_entityID" ON "transactionHistoryIndex"("address", "network", "contract", "dateTime", "entityID")

    CREATE TABLE "transactionHistoryIndex" ("entityType" TEXT NOT NULL, "entityID" TEXT NOT NULL, "address" TEXT NOT NULL, "network" TEXT NOT NULL, "contract" TEXT NOT NULL, "dateTime" DATETIME NOT NULL, PRIMARY KEY ("entityType", "entityID", "address", "network", "contract"))
    """
}
