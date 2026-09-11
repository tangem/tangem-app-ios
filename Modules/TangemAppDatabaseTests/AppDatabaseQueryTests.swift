//
//  AppDatabaseQueryTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

@Suite("AppDatabase query helpers")
struct AppDatabaseQueryTests {
    @Test("History index info query resolves the full exchange graph")
    func historyIndexInfoQueryResolvesExchangeGraph() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let provider = AppDatabaseFixtures.makeFullProviderRecord(id: "changelly", type: "cex")
        let fromCurrency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let toCurrency = AppDatabaseFixtures.makeMinimalCryptoCurrencyRecord(
            networkID: "bitcoin",
            contractAddress: AppDatabaseFixtures.coinContractAddress
        )
        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: provider.id,
            fromNetwork: fromCurrency.networkID,
            fromContract: fromCurrency.contractAddress,
            toNetwork: toCurrency.networkID,
            toContract: toCurrency.contractAddress,
            refundNetwork: fromCurrency.networkID,
            refundContractAddress: fromCurrency.contractAddress
        )
        let historyIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: transaction.id,
            address: transaction.ownerAddress,
            network: toCurrency.networkID,
            contract: toCurrency.contractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try provider.insert(database)
            try fromCurrency.insert(database)
            try toCurrency.insert(database)
            try transaction.insert(database)
            try historyIndex.insert(database)
        }

        let fetchedInfos = try databaseQueue.read { database in
            try TransactionHistoryIndexInfoRecord
                .query(address: historyIndex.address, network: historyIndex.network, contractAddress: historyIndex.contract)
                .fetchAll(database)
        }

        #expect(fetchedInfos.count == 1)

        let info = try #require(fetchedInfos.first)
        try expectSameDatabaseRepresentation(info.indexRecord, historyIndex)
        #expect(info.onrampTransaction == nil)

        let exchangeRecords = try #require(info.exchangeTransaction)
        try expectSameDatabaseRepresentation(exchangeRecords.transaction, transaction)
        try expectSameDatabaseRepresentation(try #require(exchangeRecords.provider), provider)
        try expectSameDatabaseRepresentation(try #require(exchangeRecords.fromCryptoCurrency), fromCurrency)
        try expectSameDatabaseRepresentation(try #require(exchangeRecords.toCryptoCurrency), toCurrency)
        try expectSameDatabaseRepresentation(try #require(exchangeRecords.refundCryptoCurrency), fromCurrency)
    }

    @Test("History index info query resolves the full onramp graph")
    func historyIndexInfoQueryResolvesOnrampGraph() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let provider = AppDatabaseFixtures.makeFullProviderRecord(id: "mercuryo", type: "onramp")
        let fiatCurrency = AppDatabaseFixtures.makeFullFiatCurrencyRecord()
        let cryptoCurrency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let transaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: "onramp-tx-1",
            providerID: provider.id,
            fromCurrency: fiatCurrency.code,
            toNetwork: cryptoCurrency.networkID,
            toContract: cryptoCurrency.contractAddress
        )
        let historyIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressOnramp,
            entityID: transaction.id,
            address: transaction.payOutAddress,
            network: cryptoCurrency.networkID,
            contract: cryptoCurrency.contractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try provider.insert(database)
            try fiatCurrency.insert(database)
            try cryptoCurrency.insert(database)
            try transaction.insert(database)
            try historyIndex.insert(database)
        }

        let fetchedInfos = try databaseQueue.read { database in
            try TransactionHistoryIndexInfoRecord
                .query(address: historyIndex.address, network: historyIndex.network, contractAddress: historyIndex.contract)
                .fetchAll(database)
        }

        #expect(fetchedInfos.count == 1)

        let info = try #require(fetchedInfos.first)
        try expectSameDatabaseRepresentation(info.indexRecord, historyIndex)
        #expect(info.exchangeTransaction == nil)

        let onrampRecords = try #require(info.onrampTransaction)
        try expectSameDatabaseRepresentation(onrampRecords.transaction, transaction)
        try expectSameDatabaseRepresentation(try #require(onrampRecords.provider), provider)
        try expectSameDatabaseRepresentation(try #require(onrampRecords.fiatCurrency), fiatCurrency)
        try expectSameDatabaseRepresentation(try #require(onrampRecords.cryptoCurrency), cryptoCurrency)
    }

    @Test("History index info query returns only exact matches of the address, network, and contract")
    func historyIndexInfoQueryFiltersByExactMatch() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let contract = AppDatabaseFixtures.mixedCaseContractAddress
        let matchingIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-1",
            address: "0xOwner",
            network: "ethereum",
            contract: contract,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let wrongAddressIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-2",
            address: "0xOther",
            network: "ethereum",
            contract: contract,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let wrongNetworkIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-3",
            address: "0xOwner",
            network: "polygon",
            contract: contract,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let wrongContractIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-4",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let caseVariantContractIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-5",
            address: "0xOwner",
            network: "ethereum",
            contract: contract.lowercased(),
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try matchingIndex.insert(database)
            try wrongAddressIndex.insert(database)
            try wrongNetworkIndex.insert(database)
            try wrongContractIndex.insert(database)
            try caseVariantContractIndex.insert(database)
        }

        let fetchedInfos = try databaseQueue.read { database in
            try TransactionHistoryIndexInfoRecord
                .query(address: matchingIndex.address, network: matchingIndex.network, contractAddress: matchingIndex.contract)
                .fetchAll(database)
        }

        #expect(fetchedInfos.map(\.indexRecord.entityID) == ["tx-1"])
    }

    @Test("History index info query orders by date descending, then by entity id descending")
    func historyIndexInfoQueryOrdersByDateTimeThenEntityID() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let olderDate = Date(timeIntervalSince1970: 1_752_000_000.125)
        let newerDate = Date(timeIntervalSince1970: 1_752_003_600.5)
        let newerIndexWithLesserID = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-a",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: newerDate
        )
        let newerIndexWithGreaterID = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-b",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: newerDate
        )
        let olderIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: "tx-c",
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: olderDate
        )

        try databaseQueue.write { database in
            try newerIndexWithLesserID.insert(database)
            try newerIndexWithGreaterID.insert(database)
            try olderIndex.insert(database)
        }

        let fetchedInfos = try databaseQueue.read { database in
            try TransactionHistoryIndexInfoRecord
                .query(address: olderIndex.address, network: olderIndex.network, contractAddress: olderIndex.contract)
                .fetchAll(database)
        }

        #expect(fetchedInfos.map(\.indexRecord.entityID) == ["tx-b", "tx-a", "tx-c"])
    }

    @Test("Transactions with missing cache rows still appear in the query results")
    func historyIndexInfoQueryKeepsTransactionsWithMissingCacheRows() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "changelly",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let historyIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: transaction.id,
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try transaction.insert(database)
            try historyIndex.insert(database)
        }

        let fetchedInfos = try databaseQueue.read { database in
            try TransactionHistoryIndexInfoRecord
                .query(address: historyIndex.address, network: historyIndex.network, contractAddress: historyIndex.contract)
                .fetchAll(database)
        }

        let info = try #require(fetchedInfos.first)
        let exchangeRecords = try #require(info.exchangeTransaction)
        try expectSameDatabaseRepresentation(exchangeRecords.transaction, transaction)
        #expect(exchangeRecords.provider == nil)
        #expect(exchangeRecords.fromCryptoCurrency == nil)
        #expect(exchangeRecords.toCryptoCurrency == nil)
        #expect(exchangeRecords.refundCryptoCurrency == nil)
    }

    @Test("Sync metadata filter by owner and endpoint type returns the single matching row")
    func syncMetadataFilterByOwnerAndEndpointTypeReturnsSingleRow() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let matchingRecord = AppDatabaseFixtures.makeFullSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "exchange")
        let otherEndpointRecord = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "onramp")
        let otherOwnerRecord = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOther", endpointType: "exchange")

        try databaseQueue.write { database in
            try matchingRecord.insert(database)
            try otherEndpointRecord.insert(database)
            try otherOwnerRecord.insert(database)
        }

        let fetchedRecords = try databaseQueue.read { database in
            try ExpressSyncMetadataRecord
                .filter(ownerAddress: matchingRecord.ownerAddress, endpointType: matchingRecord.endpointType)
                .fetchAll(database)
        }

        #expect(fetchedRecords.count == 1)
        try expectSameDatabaseRepresentation(try #require(fetchedRecords.first), matchingRecord)
    }

    @Test("Sync metadata filter by owner returns the rows of all endpoint types")
    func syncMetadataFilterByOwnerReturnsAllEndpointTypeRows() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let exchangeRecord = AppDatabaseFixtures.makeFullSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "exchange")
        let onrampRecord = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOwner", endpointType: "onramp")
        let otherOwnerRecord = AppDatabaseFixtures.makeMinimalSyncMetadataRecord(ownerAddress: "0xOther", endpointType: "exchange")

        try databaseQueue.write { database in
            try exchangeRecord.insert(database)
            try onrampRecord.insert(database)
            try otherOwnerRecord.insert(database)
        }

        let fetchedEndpointTypes = try databaseQueue.read { database in
            try ExpressSyncMetadataRecord
                .filter(ownerAddress: exchangeRecord.ownerAddress)
                .fetchAll(database)
                .map(\.endpointType)
                .sorted()
        }

        #expect(fetchedEndpointTypes == ["exchange", "onramp"])
    }
}
