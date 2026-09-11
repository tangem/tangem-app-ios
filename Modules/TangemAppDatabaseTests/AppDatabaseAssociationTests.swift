//
//  AppDatabaseAssociationTests.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

@Suite("AppDatabase associations")
struct AppDatabaseAssociationTests {
    @Test("Exchange transaction resolves the provider and all currency legs")
    func exchangeTransactionResolvesAllAssociations() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let provider = AppDatabaseFixtures.makeFullProviderRecord(id: "changelly", type: "cex")
        let tokenCurrency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let coinCurrency = AppDatabaseFixtures.makeMinimalCryptoCurrencyRecord(
            networkID: "bitcoin",
            contractAddress: AppDatabaseFixtures.coinContractAddress
        )
        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: provider.id,
            fromNetwork: tokenCurrency.networkID,
            fromContract: tokenCurrency.contractAddress,
            toNetwork: coinCurrency.networkID,
            toContract: coinCurrency.contractAddress,
            refundNetwork: tokenCurrency.networkID,
            refundContractAddress: tokenCurrency.contractAddress
        )

        try databaseQueue.write { database in
            try provider.insert(database)
            try tokenCurrency.insert(database)
            try coinCurrency.insert(database)
            try transaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(relations.transaction, transaction)
        try expectSameDatabaseRepresentation(try #require(relations.provider), provider)
        try expectSameDatabaseRepresentation(try #require(relations.fromCryptoCurrency), tokenCurrency)
        try expectSameDatabaseRepresentation(try #require(relations.toCryptoCurrency), coinCurrency)
        try expectSameDatabaseRepresentation(try #require(relations.refundCryptoCurrency), tokenCurrency)
    }

    @Test("Contract address joins are case-sensitive")
    func contractAddressJoinIsCaseSensitive() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let currency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord(
            networkID: "ethereum",
            contractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let matchingTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "changelly",
            fromNetwork: currency.networkID,
            fromContract: currency.contractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: nil,
            refundContractAddress: nil
        )
        let caseMismatchedTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-2",
            providerID: "changelly",
            fromNetwork: currency.networkID,
            fromContract: currency.contractAddress.lowercased(),
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: nil,
            refundContractAddress: nil
        )

        try databaseQueue.write { database in
            try currency.insert(database)
            try matchingTransaction.insert(database)
            try caseMismatchedTransaction.insert(database)
        }

        let fetchedMatchingRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest()
                .filter(ExpressExchangeTransactionRecord.Columns.id == matchingTransaction.id)
                .fetchOne(database)
        }
        let fetchedMismatchedRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest()
                .filter(ExpressExchangeTransactionRecord.Columns.id == caseMismatchedTransaction.id)
                .fetchOne(database)
        }

        let matchingRelations = try #require(fetchedMatchingRelations)
        try expectSameDatabaseRepresentation(try #require(matchingRelations.fromCryptoCurrency), currency)

        let mismatchedRelations = try #require(fetchedMismatchedRelations)
        #expect(mismatchedRelations.fromCryptoCurrency == nil)
    }

    @Test("Onramp transaction resolves the provider and both currencies")
    func onrampTransactionResolvesAllAssociations() throws {
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

        try databaseQueue.write { database in
            try provider.insert(database)
            try fiatCurrency.insert(database)
            try cryptoCurrency.insert(database)
            try transaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeOnrampTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(relations.transaction, transaction)
        try expectSameDatabaseRepresentation(try #require(relations.provider), provider)
        try expectSameDatabaseRepresentation(try #require(relations.fiatCurrency), fiatCurrency)
        try expectSameDatabaseRepresentation(try #require(relations.cryptoCurrency), cryptoCurrency)
    }

    /// Providers have a composite (id, type) primary key, so the same id may exist once per branch;
    /// the provider associations join on id and filter by the branch's supported type literals.
    @Test("Provider association resolves the row matching the transaction's branch")
    func providerAssociationSelectsBranchSpecificRow() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let swapProvider = AppDatabaseFixtures.makeFullProviderRecord(id: "dual", type: "cex")
        let onrampProvider = AppDatabaseFixtures.makeFullProviderRecord(id: "dual", type: "onramp")
        let exchangeTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "dual",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let onrampTransaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: "onramp-tx-1",
            providerID: "dual",
            fromCurrency: "USD",
            toNetwork: "ethereum",
            toContract: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try databaseQueue.write { database in
            try swapProvider.insert(database)
            try onrampProvider.insert(database)
            try exchangeTransaction.insert(database)
            try onrampTransaction.insert(database)
        }

        let fetchedExchangeRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest().fetchOne(database)
        }
        let fetchedOnrampRelations = try databaseQueue.read { database in
            try Self.makeOnrampTransactionRequest().fetchOne(database)
        }

        let exchangeRelations = try #require(fetchedExchangeRelations)
        try expectSameDatabaseRepresentation(try #require(exchangeRelations.provider), swapProvider)

        let onrampRelations = try #require(fetchedOnrampRelations)
        try expectSameDatabaseRepresentation(try #require(onrampRelations.provider), onrampProvider)
    }

    @Test("Provider of a foreign branch does not resolve")
    func providerOfForeignBranchDoesNotResolve() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let onrampProvider = AppDatabaseFixtures.makeFullProviderRecord(id: "dual", type: "onramp")
        let exchangeTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "dual",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )

        try databaseQueue.write { database in
            try onrampProvider.insert(database)
            try exchangeTransaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        #expect(relations.provider == nil)
    }

    @Test("History index resolves its entity for each branch")
    func historyIndexResolvesEntityForEachBranch() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let exchangeTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "changelly",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let onrampTransaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: "onramp-tx-1",
            providerID: "mercuryo",
            fromCurrency: "USD",
            toNetwork: "ethereum",
            toContract: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let exchangeIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: exchangeTransaction.id,
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let onrampIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressOnramp,
            entityID: onrampTransaction.id,
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try exchangeTransaction.insert(database)
            try onrampTransaction.insert(database)
            try exchangeIndex.insert(database)
            try onrampIndex.insert(database)
        }

        let fetchedExchangeRelations = try databaseQueue.read { database in
            try Self.makeHistoryIndexRequest()
                .filter(TransactionHistoryIndexRecord.Columns.entityID == exchangeTransaction.id)
                .fetchOne(database)
        }
        let fetchedOnrampRelations = try databaseQueue.read { database in
            try Self.makeHistoryIndexRequest()
                .filter(TransactionHistoryIndexRecord.Columns.entityID == onrampTransaction.id)
                .fetchOne(database)
        }

        let exchangeRelations = try #require(fetchedExchangeRelations)
        try expectSameDatabaseRepresentation(exchangeRelations.historyIndex, exchangeIndex)
        try expectSameDatabaseRepresentation(try #require(exchangeRelations.expressEntity), exchangeTransaction)
        #expect(exchangeRelations.onrampEntity == nil)

        let onrampRelations = try #require(fetchedOnrampRelations)
        try expectSameDatabaseRepresentation(onrampRelations.historyIndex, onrampIndex)
        try expectSameDatabaseRepresentation(try #require(onrampRelations.onrampEntity), onrampTransaction)
        #expect(onrampRelations.expressEntity == nil)
    }

    @Test("Entity associations join by ID alone, without discriminating by entity type")
    func historyIndexEntityAssociationsJoinByIDAlone() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let exchangeTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "shared-tx-1",
            providerID: "changelly",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let onrampTransaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: exchangeTransaction.id,
            providerID: "mercuryo",
            fromCurrency: "USD",
            toNetwork: "ethereum",
            toContract: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let exchangeIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: exchangeTransaction.id,
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try exchangeTransaction.insert(database)
            try onrampTransaction.insert(database)
            try exchangeIndex.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeHistoryIndexRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(try #require(relations.expressEntity), exchangeTransaction)
        try expectSameDatabaseRepresentation(try #require(relations.onrampEntity), onrampTransaction)
    }

    @Test("Transactions resolve their history index rows through the inverse association")
    func transactionsResolveHistoryIndexRows() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let exchangeTransaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            id: "exchange-tx-1",
            providerID: "changelly",
            fromNetwork: "ethereum",
            fromContract: AppDatabaseFixtures.mixedCaseContractAddress,
            toNetwork: "bitcoin",
            toContract: AppDatabaseFixtures.coinContractAddress,
            refundNetwork: "ethereum",
            refundContractAddress: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let onrampTransaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
            id: "onramp-tx-1",
            providerID: "mercuryo",
            fromCurrency: "USD",
            toNetwork: "ethereum",
            toContract: AppDatabaseFixtures.mixedCaseContractAddress
        )
        let fromLegExchangeIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: exchangeTransaction.id,
            address: "0xFrom",
            network: "ethereum",
            contract: AppDatabaseFixtures.mixedCaseContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let payOutLegExchangeIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: exchangeTransaction.id,
            address: "0xPayOut",
            network: "bitcoin",
            contract: AppDatabaseFixtures.coinContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
        let onrampIndex = AppDatabaseFixtures.makeHistoryIndexRecord(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressOnramp,
            entityID: onrampTransaction.id,
            address: "0xOwner",
            network: "ethereum",
            contract: AppDatabaseFixtures.mixedCaseContractAddress,
            dateTime: Date(timeIntervalSince1970: 1_752_000_000.125)
        )

        try databaseQueue.write { database in
            try exchangeTransaction.insert(database)
            try onrampTransaction.insert(database)
            try fromLegExchangeIndex.insert(database)
            try payOutLegExchangeIndex.insert(database)
            try onrampIndex.insert(database)
        }

        let fetchedExchangeRelations = try databaseQueue.read { database in
            try ExpressExchangeTransactionRecord
                .including(all: ExpressExchangeTransactionRecord.historyIndexRecords)
                .asRequest(of: ExchangeTransactionWithHistoryIndexes.self)
                .fetchOne(database)
        }
        let fetchedOnrampRelations = try databaseQueue.read { database in
            try ExpressOnrampTransactionRecord
                .including(all: ExpressOnrampTransactionRecord.historyIndexRecords)
                .asRequest(of: OnrampTransactionWithHistoryIndexes.self)
                .fetchOne(database)
        }

        let exchangeRelations = try #require(fetchedExchangeRelations)
        let exchangeAddresses = exchangeRelations.historyIndexRecords.map(\.address).sorted()
        #expect(exchangeAddresses == ["0xFrom", "0xPayOut"])

        let onrampRelations = try #require(fetchedOnrampRelations)
        #expect(onrampRelations.historyIndexRecords.count == 1)
        try expectSameDatabaseRepresentation(try #require(onrampRelations.historyIndexRecords.first), onrampIndex)
    }
}

// MARK: - Private implementation

private extension AppDatabaseAssociationTests {
    /// Property names must match the association keys declared on the records;
    /// `transaction` matches no association key and therefore decodes from the base row.
    struct ExchangeTransactionWithRelations: Decodable, FetchableRecord {
        let transaction: ExpressExchangeTransactionRecord
        let provider: ExpressProviderRecord?
        let fromCryptoCurrency: CryptoCurrencyRecord?
        let toCryptoCurrency: CryptoCurrencyRecord?
        let refundCryptoCurrency: CryptoCurrencyRecord?
    }

    struct OnrampTransactionWithRelations: Decodable, FetchableRecord {
        let transaction: ExpressOnrampTransactionRecord
        let provider: ExpressProviderRecord?
        let fiatCurrency: FiatCurrencyRecord?
        let cryptoCurrency: CryptoCurrencyRecord?
    }

    struct HistoryIndexWithEntities: Decodable, FetchableRecord {
        let historyIndex: TransactionHistoryIndexRecord
        let expressEntity: ExpressExchangeTransactionRecord?
        let onrampEntity: ExpressOnrampTransactionRecord?
    }

    struct ExchangeTransactionWithHistoryIndexes: Decodable, FetchableRecord {
        let transaction: ExpressExchangeTransactionRecord
        let historyIndexRecords: [TransactionHistoryIndexRecord]
    }

    struct OnrampTransactionWithHistoryIndexes: Decodable, FetchableRecord {
        let transaction: ExpressOnrampTransactionRecord
        let historyIndexRecords: [TransactionHistoryIndexRecord]
    }

    static func makeExchangeTransactionRequest() -> QueryInterfaceRequest<ExchangeTransactionWithRelations> {
        ExpressExchangeTransactionRecord
            .including(optional: ExpressExchangeTransactionRecord.provider)
            .including(optional: ExpressExchangeTransactionRecord.fromCryptoCurrency)
            .including(optional: ExpressExchangeTransactionRecord.toCryptoCurrency)
            .including(optional: ExpressExchangeTransactionRecord.refundCryptoCurrency)
            .asRequest(of: ExchangeTransactionWithRelations.self)
    }

    static func makeOnrampTransactionRequest() -> QueryInterfaceRequest<OnrampTransactionWithRelations> {
        ExpressOnrampTransactionRecord
            .including(optional: ExpressOnrampTransactionRecord.provider)
            .including(optional: ExpressOnrampTransactionRecord.fiatCurrency)
            .including(optional: ExpressOnrampTransactionRecord.cryptoCurrency)
            .asRequest(of: OnrampTransactionWithRelations.self)
    }

    static func makeHistoryIndexRequest() -> QueryInterfaceRequest<HistoryIndexWithEntities> {
        TransactionHistoryIndexRecord
            .including(optional: TransactionHistoryIndexRecord.expressEntity)
            .including(optional: TransactionHistoryIndexRecord.onrampEntity)
            .asRequest(of: HistoryIndexWithEntities.self)
    }
}
