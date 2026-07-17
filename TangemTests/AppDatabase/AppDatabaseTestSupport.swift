//
//  AppDatabaseTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemExpress
import Testing
@testable import Tangem

/// Use this tag for all app-database suites: @Suite(.tags(.appDatabase))
extension Tag {
    @Tag static var appDatabase: Self
}

// MARK: - Factories

enum AppDatabaseTestFactory {
    /// Returns an in-memory database queue migrated through the full migration chain.
    static func makeMigratedDatabaseQueue() throws -> DatabaseQueue {
        let databaseQueue = try DatabaseQueue()
        let appDatabase = AppDatabase { _ in databaseQueue }
        _ = try appDatabase.databaseHandle

        return databaseQueue
    }
}

// MARK: - Fixtures

enum AppDatabaseFixtures {
    static let mixedCaseContractAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

    /// GRDB stores `.datetime` columns as `yyyy-MM-dd HH:mm:ss.SSS` strings, truncating
    /// sub-millisecond precision. Fixture dates must stay millisecond-exact for round-trip
    /// comparisons to hold, hence fractional parts limited to values representable in both
    /// binary and milliseconds (.0, .5, .25, .125).
    static func makeDate(secondsSince1970: TimeInterval = 1_752_000_000.125) -> Date {
        Date(timeIntervalSince1970: secondsSince1970)
    }

    // MARK: Providers cache

    static func makeFullProviderRecord(id: String = "changelly") -> ExpressProviderRecord {
        ExpressProviderRecord(
            id: id,
            name: "Changelly",
            type: "cex",
            exchangeOnlyWithinSingleAddress: false,
            imageURL: "https://example.com/changelly.png",
            termsOfUse: "https://example.com/terms",
            privacyPolicy: "https://example.com/privacy",
            recommended: true,
            slippage: "1.5",
            updatedAt: makeDate()
        )
    }

    static func makeMinimalProviderRecord(id: String = "changelly") -> ExpressProviderRecord {
        ExpressProviderRecord(
            id: id,
            name: "Changelly",
            type: "cex",
            exchangeOnlyWithinSingleAddress: true,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            updatedAt: makeDate()
        )
    }

    // MARK: Fiat currencies cache

    static func makeFullFiatCurrencyRecord(code: String = "USD") -> FiatCurrencyRecord {
        FiatCurrencyRecord(
            code: code,
            name: "United States Dollar",
            imageURL: "https://example.com/usd.png",
            precision: 2,
            updatedAt: makeDate()
        )
    }

    static func makeMinimalFiatCurrencyRecord(code: String = "USD") -> FiatCurrencyRecord {
        FiatCurrencyRecord(
            code: code,
            name: "United States Dollar",
            imageURL: nil,
            precision: 2,
            updatedAt: makeDate()
        )
    }

    // MARK: Crypto currencies cache

    static func makeFullCryptoCurrencyRecord(
        networkID: String = "ethereum",
        contractAddress: String = mixedCaseContractAddress
    ) -> CryptoCurrencyRecord {
        CryptoCurrencyRecord(
            id: "usd-coin",
            networkID: networkID,
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: contractAddress,
            decimalCount: 6,
            updatedAt: makeDate()
        )
    }

    static func makeMinimalCryptoCurrencyRecord(
        networkID: String = "ethereum",
        contractAddress: String = ExpressConstants.coinContractAddress
    ) -> CryptoCurrencyRecord {
        CryptoCurrencyRecord(
            id: nil,
            networkID: networkID,
            name: "Ethereum",
            symbol: "ETH",
            contractAddress: contractAddress,
            decimalCount: 18,
            updatedAt: makeDate()
        )
    }

    // MARK: Exchange transactions

    static func makeFullExchangeTransactionRecord(
        id: String = "exchange-tx-1",
        providerID: String = "changelly",
        fromNetwork: String = "ethereum",
        fromContract: String = mixedCaseContractAddress,
        toNetwork: String = "bitcoin",
        toContract: String = ExpressConstants.coinContractAddress,
        refundNetwork: String? = "ethereum",
        refundContractAddress: String? = mixedCaseContractAddress
    ) -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: id,
            ownerAddress: "0xOwner",
            providerID: providerID,
            fromAddress: "0xFrom",
            payInAddress: "0xPayIn",
            payOutAddress: "0xPayOut",
            status: "failed",
            externalTxID: "external-tx-1",
            externalTxURL: "https://example.com/tx/external-tx-1",
            payInHash: "0xPayInHash",
            payOutHash: "0xPayOutHash",
            fromNetwork: fromNetwork,
            fromContract: fromContract,
            fromAmount: "100.5",
            fromDecimals: 6,
            toNetwork: toNetwork,
            toContract: toContract,
            toAmount: "0.002",
            toDecimals: 8,
            toActualAmount: "0.0019",
            failReason: "refunded",
            refundAddress: "0xRefund",
            refundNetwork: refundNetwork,
            refundContractAddress: refundContractAddress,
            createdAt: makeDate(),
            updatedAt: makeDate(secondsSince1970: 1_752_003_600.5)
        )
    }

    static func makeMinimalExchangeTransactionRecord(id: String = "exchange-tx-1") -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: id,
            ownerAddress: "0xOwner",
            providerID: "changelly",
            fromAddress: nil,
            payInAddress: nil,
            payOutAddress: nil,
            status: "waiting",
            externalTxID: nil,
            externalTxURL: nil,
            payInHash: nil,
            payOutHash: nil,
            fromNetwork: "ethereum",
            fromContract: ExpressConstants.coinContractAddress,
            fromAmount: "0.1",
            fromDecimals: 18,
            toNetwork: "bitcoin",
            toContract: ExpressConstants.coinContractAddress,
            toAmount: "0.002",
            toDecimals: 8,
            toActualAmount: nil,
            failReason: nil,
            refundAddress: nil,
            refundNetwork: nil,
            refundContractAddress: nil,
            createdAt: makeDate(),
            updatedAt: makeDate()
        )
    }

    // MARK: Onramp transactions

    static func makeFullOnrampTransactionRecord(
        id: String = "onramp-tx-1",
        providerID: String = "mercuryo",
        fromCurrency: String = "USD",
        toNetwork: String = "ethereum",
        toContract: String = mixedCaseContractAddress
    ) -> ExpressOnrampTransactionRecord {
        ExpressOnrampTransactionRecord(
            id: id,
            ownerAddress: "0xOwner",
            providerID: providerID,
            payOutAddress: "0xPayOut",
            status: "failed",
            externalTxID: "external-tx-2",
            externalTxURL: "https://example.com/tx/external-tx-2",
            payOutHash: "0xPayOutHash",
            fromCurrency: fromCurrency,
            fromAmount: "250",
            fromDecimals: 2,
            toNetwork: toNetwork,
            toContract: toContract,
            toAmount: "249.5",
            toDecimals: 6,
            toActualAmount: "249.4",
            failReason: "provider-error",
            createdAt: makeDate(),
            updatedAt: makeDate(secondsSince1970: 1_752_003_600.5)
        )
    }

    static func makeMinimalOnrampTransactionRecord(id: String = "onramp-tx-1") -> ExpressOnrampTransactionRecord {
        ExpressOnrampTransactionRecord(
            id: id,
            ownerAddress: "0xOwner",
            providerID: "mercuryo",
            payOutAddress: nil,
            status: "created",
            externalTxID: nil,
            externalTxURL: nil,
            payOutHash: nil,
            fromCurrency: "USD",
            fromAmount: "250",
            fromDecimals: nil,
            toNetwork: "ethereum",
            toContract: ExpressConstants.coinContractAddress,
            toAmount: "0.07",
            toDecimals: 18,
            toActualAmount: nil,
            failReason: nil,
            createdAt: makeDate(),
            updatedAt: makeDate()
        )
    }

    // MARK: Sync metadata

    static func makeFullSyncMetadataRecord(
        ownerAddress: String = "0xOwner",
        endpointType: String = "exchange"
    ) -> ExpressSyncMetadataRecord {
        ExpressSyncMetadataRecord(
            ownerAddress: ownerAddress,
            endpointType: endpointType,
            archiveCursor: "archive-cursor-1",
            deltaCursor: "delta-cursor-1",
            isInitialSyncDone: true,
            lastSyncAt: makeDate()
        )
    }

    static func makeMinimalSyncMetadataRecord(
        ownerAddress: String = "0xOwner",
        endpointType: String = "exchange"
    ) -> ExpressSyncMetadataRecord {
        ExpressSyncMetadataRecord(
            ownerAddress: ownerAddress,
            endpointType: endpointType,
            archiveCursor: nil,
            deltaCursor: nil,
            isInitialSyncDone: false,
            lastSyncAt: makeDate()
        )
    }
}

// MARK: - Expectations

/// Compares database representations rather than Swift values: the records don't conform to
/// `Equatable` (synthesis is unavailable outside the defining file), and re-encoding both sides
/// keeps `Date` comparisons at the millisecond precision the database actually stores.
func expectSameDatabaseRepresentation<Record: EncodableRecord>(
    _ fetchedRecord: Record,
    _ originalRecord: Record,
    sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let fetchedRepresentation = try fetchedRecord.databaseDictionary
    let originalRepresentation = try originalRecord.databaseDictionary

    #expect(fetchedRepresentation == originalRepresentation, sourceLocation: sourceLocation)
}
