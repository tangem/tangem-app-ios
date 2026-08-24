//
//  AppDatabaseRecordRoundTripTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

/// The coupling between the DDL and the records is stringly-typed, so the compiler can't catch
/// a non-optional record property sitting on a nullable column, or Date/Bool bridging mistakes.
/// A round-trip with a fully populated record plus one with every optional nil covers both
/// directions of each column's nullability.
@Suite("AppDatabase record round-trips")
struct AppDatabaseRecordRoundTripTests {
    @Test("Fully populated ExpressProviderRecord round-trips")
    func fullProviderRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullProviderRecord(id: "changelly", type: "cex")

        try performRoundTrip(of: record) { database in
            try ExpressProviderRecord.fetchOne(database, key: ["id": record.id, "type": record.type])
        }
    }

    @Test("ExpressProviderRecord with all optionals nil round-trips")
    func minimalProviderRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalProviderRecord(id: "changelly", type: "cex")

        try performRoundTrip(of: record) { database in
            try ExpressProviderRecord.fetchOne(database, key: ["id": record.id, "type": record.type])
        }
    }

    @Test("Fully populated FiatCurrencyRecord round-trips")
    func fullFiatCurrencyRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullFiatCurrencyRecord()

        try performRoundTrip(of: record) { database in
            try FiatCurrencyRecord.fetchOne(database, key: record.code)
        }
    }

    @Test("FiatCurrencyRecord with all optionals nil round-trips")
    func minimalFiatCurrencyRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalFiatCurrencyRecord()

        try performRoundTrip(of: record) { database in
            try FiatCurrencyRecord.fetchOne(database, key: record.code)
        }
    }

    @Test("Fully populated CryptoCurrencyRecord round-trips")
    func fullCryptoCurrencyRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try performRoundTrip(of: record) { database in
            try CryptoCurrencyRecord.fetchOne(
                database,
                key: ["networkID": record.networkID, "contractAddress": record.contractAddress]
            )
        }
    }

    @Test("CryptoCurrencyRecord with all optionals nil round-trips")
    func minimalCryptoCurrencyRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.coinContractAddress
        )

        try performRoundTrip(of: record) { database in
            try CryptoCurrencyRecord.fetchOne(
                database,
                key: ["networkID": record.networkID, "contractAddress": record.contractAddress]
            )
        }
    }

    @Test("Fully populated ExpressExchangeTransactionRecord round-trips")
    func fullExchangeTransactionRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "changelly",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try performRoundTrip(of: record) { database in
            try ExpressExchangeTransactionRecord.fetchOne(database, key: record.id)
        }
    }

    @Test("ExpressExchangeTransactionRecord with all optionals nil round-trips")
    func minimalExchangeTransactionRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalExchangeTransactionRecord()

        try performRoundTrip(of: record) { database in
            try ExpressExchangeTransactionRecord.fetchOne(database, key: record.id)
        }
    }

    @Test("Fully populated ExpressOnrampTransactionRecord round-trips")
    func fullOnrampTransactionRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: "onramp-tx-1",
            providerID: "mercuryo",
            fromCurrency: "USD",
            toNetwork: "ethereum",
            toContract: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try performRoundTrip(of: record) { database in
            try ExpressOnrampTransactionRecord.fetchOne(database, key: record.id)
        }
    }

    @Test("ExpressOnrampTransactionRecord with all optionals nil round-trips")
    func minimalOnrampTransactionRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalOnrampTransactionRecord()

        try performRoundTrip(of: record) { database in
            try ExpressOnrampTransactionRecord.fetchOne(database, key: record.id)
        }
    }

    @Test("Fully populated ExpressSyncMetadataRecord round-trips")
    func fullSyncMetadataRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeFullSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "exchange")

        try performRoundTrip(of: record) { database in
            try ExpressSyncMetadataRecord.fetchOne(
                database,
                key: ["ownerAddress": record.ownerAddress, "endpointType": record.endpointType]
            )
        }
    }

    @Test("ExpressSyncMetadataRecord with all optionals nil round-trips")
    func minimalSyncMetadataRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "exchange")

        try performRoundTrip(of: record) { database in
            try ExpressSyncMetadataRecord.fetchOne(
                database,
                key: ["ownerAddress": record.ownerAddress, "endpointType": record.endpointType]
            )
        }
    }

    @Test("TransactionHistoryIndexRecord round-trips")
    func historyIndexRecordRoundTrips() throws {
        let record = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "exchange-tx-1",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try performRoundTrip(of: record) { database in
            try TransactionHistoryIndexRecord.fetchOne(
                database,
                key: [
                    "entityType": record.entityType,
                    "entityID": record.entityID,
                    "address": record.address,
                    "network": record.network,
                    "contract": record.contract,
                ]
            )
        }
    }

    /// Inserting via raw SQL with only the NOT NULL columns exercises the table-nullability vs
    /// record-optionality contract independently of the record encoder: the nil round-trips above
    /// can never omit a non-optional property, so they can't catch one sitting on a nullable column.
    @Test("Rows containing only NOT NULL columns decode into records")
    func rowsWithOnlyRequiredColumnsDecode() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        try databaseQueue.write { database in
            try database.execute(sql: """
            INSERT INTO expressProvidersCache (id, name, type, exchangeOnlyWithinSingleAddress, updatedAt)
            VALUES ('provider-1', 'Provider', 'cex', 1, '2026-07-27 00:00:00.000')
            """)
            try database.execute(sql: """
            INSERT INTO fiatCurrenciesCache (code, name, precision, updatedAt)
            VALUES ('USD', 'United States Dollar', 2, '2026-07-27 00:00:00.000')
            """)
            try database.execute(sql: """
            INSERT INTO cryptoCurrenciesCache (networkID, name, symbol, contractAddress, decimalCount, updatedAt)
            VALUES ('ethereum', 'Ethereum', 'ETH', '0', 18, '2026-07-27 00:00:00.000')
            """)
            try database.execute(sql: """
            INSERT INTO expressExchangeTransactions (
                id, ownerAddress, providerID, payInAddress, payOutAddress, status,
                fromNetwork, fromContract, fromAmount, fromDecimals,
                toNetwork, toContract, toAmount, toDecimals,
                createdAt, updatedAt
            )
            VALUES (
                'exchange-tx-1', '0xOwner', 'provider-1', '0xPayIn', '0xPayOut', 'waiting',
                'ethereum', '0', '0.1', 18,
                'bitcoin', '0', '0.002', 8,
                '2026-07-27 00:00:00.000', '2026-07-27 00:00:00.000'
            )
            """)
            try database.execute(sql: """
            INSERT INTO expressOnrampTransactions (
                id, ownerAddress, providerID, payOutAddress, status, fromCurrency, fromAmount,
                toNetwork, toContract, toDecimals, paymentMethod, countryCode,
                createdAt, updatedAt
            )
            VALUES (
                'onramp-tx-1', '0xOwner', 'provider-1', '0xPayOut', 'created', 'USD', '250',
                'ethereum', '0', 18, 'card', 'US',
                '2026-07-27 00:00:00.000', '2026-07-27 00:00:00.000'
            )
            """)
            try database.execute(sql: """
            INSERT INTO expressSyncMetadata (ownerAddress, endpointType, lastSyncAt)
            VALUES ('0xOwner', 'exchange', '2026-07-27 00:00:00.000')
            """)
            try database.execute(sql: """
            INSERT INTO transactionHistoryIndex (entityType, entityID, address, network, contract, dateTime)
            VALUES ('expressExchange', 'exchange-tx-1', '0xOwner', 'ethereum', '0', '2026-07-27 00:00:00.000')
            """)
        }

        try databaseQueue.read { database in
            let providerRecord = try ExpressProviderRecord.fetchOne(database, key: ["id": "provider-1", "type": "cex"])
            let fiatCurrencyRecord = try FiatCurrencyRecord.fetchOne(database, key: "USD")
            let cryptoCurrencyRecord = try CryptoCurrencyRecord.fetchOne(
                database,
                key: ["networkID": "ethereum", "contractAddress": "0"]
            )
            let exchangeTransactionRecord = try ExpressExchangeTransactionRecord.fetchOne(database, key: "exchange-tx-1")
            let onrampTransactionRecord = try ExpressOnrampTransactionRecord.fetchOne(database, key: "onramp-tx-1")
            let syncMetadataRecord = try ExpressSyncMetadataRecord.fetchOne(
                database,
                key: ["ownerAddress": "0xOwner", "endpointType": "exchange"]
            )
            let historyIndexRecord = try TransactionHistoryIndexRecord.fetchOne(
                database,
                key: [
                    "entityType": "expressExchange",
                    "entityID": "exchange-tx-1",
                    "address": "0xOwner",
                    "network": "ethereum",
                    "contract": "0",
                ]
            )

            #expect(providerRecord != nil)
            #expect(fiatCurrencyRecord != nil)
            #expect(cryptoCurrencyRecord != nil)
            #expect(exchangeTransactionRecord != nil)
            #expect(exchangeTransactionRecord?.fromActualAmount == nil)
            #expect(onrampTransactionRecord != nil)
            #expect(onrampTransactionRecord?.toAmount == nil)
            #expect(historyIndexRecord != nil)
            #expect(try #require(syncMetadataRecord).isInitialSyncDone == false)
        }
    }
}

// MARK: - Private implementation

private extension AppDatabaseRecordRoundTripTests {
    func performRoundTrip<Record: FetchableRecord & PersistableRecord>(
        of record: Record,
        fetch: (Database) throws -> Record?
    ) throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        try databaseQueue.write { database in
            try record.insert(database)
        }

        let fetchedRecord = try databaseQueue.read(fetch)

        try expectSameDatabaseRepresentation(try #require(fetchedRecord), record)
    }
}
