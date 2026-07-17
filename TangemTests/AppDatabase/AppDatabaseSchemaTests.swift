//
//  AppDatabaseSchemaTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import Tangem

@Suite("AppDatabase schema", .tags(.appDatabase))
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

    /// Renaming an applied migration would make `DatabaseMigrator` treat it as a brand-new one:
    /// an erase-and-rerun in DEBUG builds and a hard failure in production.
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
    CREATE TABLE "cryptoCurrenciesCache" ("id" TEXT, "networkID" TEXT NOT NULL, "name" TEXT NOT NULL, "symbol" TEXT NOT NULL, "contractAddress" TEXT NOT NULL COLLATE NOCASE, "decimalCount" INTEGER NOT NULL, "updatedAt" DATETIME NOT NULL, PRIMARY KEY ("networkID", "contractAddress"))

    CREATE TABLE "expressExchangeTransactions" ("id" TEXT PRIMARY KEY NOT NULL, "ownerAddress" TEXT NOT NULL, "providerID" TEXT NOT NULL, "fromAddress" TEXT, "payInAddress" TEXT, "payOutAddress" TEXT, "status" TEXT NOT NULL, "externalTxID" TEXT, "externalTxURL" TEXT, "payInHash" TEXT, "payOutHash" TEXT, "fromNetwork" TEXT NOT NULL, "fromContract" TEXT NOT NULL COLLATE NOCASE, "fromAmount" TEXT NOT NULL, "fromDecimals" INTEGER NOT NULL, "toNetwork" TEXT NOT NULL, "toContract" TEXT NOT NULL COLLATE NOCASE, "toAmount" TEXT NOT NULL, "toDecimals" INTEGER NOT NULL, "toActualAmount" TEXT, "failReason" TEXT, "refundAddress" TEXT, "refundNetwork" TEXT, "refundContractAddress" TEXT COLLATE NOCASE, "createdAt" DATETIME NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE "expressOnrampTransactions" ("id" TEXT PRIMARY KEY NOT NULL, "ownerAddress" TEXT NOT NULL, "providerID" TEXT NOT NULL, "payOutAddress" TEXT, "status" TEXT NOT NULL, "externalTxID" TEXT, "externalTxURL" TEXT, "payOutHash" TEXT, "fromCurrency" TEXT NOT NULL, "fromAmount" TEXT NOT NULL, "fromDecimals" INTEGER, "toContract" TEXT NOT NULL COLLATE NOCASE, "toNetwork" TEXT NOT NULL, "toAmount" TEXT NOT NULL, "toDecimals" INTEGER NOT NULL, "toActualAmount" TEXT, "failReason" TEXT, "createdAt" DATETIME NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE "expressProvidersCache" ("id" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "exchangeOnlyWithinSingleAddress" BOOLEAN NOT NULL, "imageURL" TEXT, "termsOfUse" TEXT, "privacyPolicy" TEXT, "recommended" BOOLEAN, "slippage" TEXT, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE "expressSyncMetadata" ("ownerAddress" TEXT NOT NULL, "endpointType" TEXT NOT NULL, "archiveCursor" TEXT, "deltaCursor" TEXT, "isInitialSyncDone" BOOLEAN NOT NULL DEFAULT 0, "lastSyncAt" DATETIME NOT NULL, PRIMARY KEY ("ownerAddress", "endpointType"))

    CREATE TABLE "fiatCurrenciesCache" ("code" TEXT PRIMARY KEY NOT NULL, "name" TEXT NOT NULL, "imageURL" TEXT, "precision" INTEGER NOT NULL, "updatedAt" DATETIME NOT NULL)

    CREATE TABLE grdb_migrations (identifier TEXT NOT NULL PRIMARY KEY)

    CREATE INDEX "idxCryptoCurrId" ON "cryptoCurrenciesCache"("id")

    CREATE INDEX "idxExFromToken" ON "expressExchangeTransactions"("fromNetwork", "fromContract", "ownerAddress")

    CREATE INDEX "idxExOwner" ON "expressExchangeTransactions"("ownerAddress")

    CREATE INDEX "idxExPayIn" ON "expressExchangeTransactions"("payInHash")

    CREATE INDEX "idxExPayOut" ON "expressExchangeTransactions"("payOutHash")

    CREATE INDEX "idxExRefundMatching" ON "expressExchangeTransactions"("status", "refundNetwork", "refundContractAddress", "refundAddress", "createdAt")

    CREATE INDEX "idxExToToken" ON "expressExchangeTransactions"("toNetwork", "toContract", "ownerAddress")

    CREATE INDEX "idxOnOwner" ON "expressOnrampTransactions"("ownerAddress")

    CREATE INDEX "idxOnPayOut" ON "expressOnrampTransactions"("payOutHash")

    CREATE INDEX "idxOnTokenFilter" ON "expressOnrampTransactions"("toNetwork", "toContract", "ownerAddress")
    """
}
