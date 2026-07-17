//
//  AppDatabaseAssociationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import Tangem

/// The provider and currency caches are soft references: a transaction must always fetch,
/// resolving whatever cache rows happen to exist and degrading to nil for the rest.
@Suite("AppDatabase associations", .tags(.appDatabase))
struct AppDatabaseAssociationTests {
    @Test("Exchange transaction resolves the provider and all currency legs")
    func exchangeTransactionResolvesAllAssociations() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let provider = AppDatabaseFixtures.makeFullProviderRecord()
        let tokenCurrency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord()
        let coinCurrency = AppDatabaseFixtures.makeMinimalCryptoCurrencyRecord(networkID: "bitcoin")
        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
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

    @Test("Exchange transaction fetches with nil relations when the caches are empty")
    func exchangeTransactionWithEmptyCachesStillFetches() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord()

        try databaseQueue.write { database in
            try transaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(relations.transaction, transaction)
        #expect(relations.provider == nil)
        #expect(relations.fromCryptoCurrency == nil)
        #expect(relations.toCryptoCurrency == nil)
        #expect(relations.refundCryptoCurrency == nil)
    }

    /// Both operands of every contract-address join carry the NOCASE collation; this pins that
    /// collation-dependent behavior so a future DDL change fails loudly.
    @Test("Contract address joins are case-insensitive")
    func contractAddressJoinIsCaseInsensitive() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let currency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord()
        let transaction = AppDatabaseFixtures.makeFullExchangeTransactionRecord(
            fromNetwork: currency.networkID,
            fromContract: currency.contractAddress.lowercased(),
            refundNetwork: nil,
            refundContractAddress: nil
        )

        try databaseQueue.write { database in
            try currency.insert(database)
            try transaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeExchangeTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(try #require(relations.fromCryptoCurrency), currency)
    }

    @Test("Onramp transaction resolves the provider and both currencies")
    func onrampTransactionResolvesAllAssociations() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()

        let provider = AppDatabaseFixtures.makeFullProviderRecord(id: "mercuryo")
        let fiatCurrency = AppDatabaseFixtures.makeFullFiatCurrencyRecord()
        let cryptoCurrency = AppDatabaseFixtures.makeFullCryptoCurrencyRecord()
        let transaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord(
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

    @Test("Onramp transaction fetches with nil relations when the caches are empty")
    func onrampTransactionWithEmptyCachesStillFetches() throws {
        let databaseQueue = try AppDatabaseTestFactory.makeMigratedDatabaseQueue()
        let transaction = AppDatabaseFixtures.makeFullOnrampTransactionRecord()

        try databaseQueue.write { database in
            try transaction.insert(database)
        }

        let fetchedRelations = try databaseQueue.read { database in
            try Self.makeOnrampTransactionRequest().fetchOne(database)
        }

        let relations = try #require(fetchedRelations)
        try expectSameDatabaseRepresentation(relations.transaction, transaction)
        #expect(relations.provider == nil)
        #expect(relations.fiatCurrency == nil)
        #expect(relations.cryptoCurrency == nil)
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
}
