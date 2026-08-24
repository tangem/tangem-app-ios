//
//  AppDatabaseTestSupport.swift
//  TangemAppDatabaseTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import Testing
@testable import TangemAppDatabase

// MARK: - Factories

enum AppDatabaseTestFactory {
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

    /// Mirrors `ExpressConstants.coinContractAddress` from the `TangemExpress` target, which SPM
    /// test targets can't import. The literal is pinned against the original
    /// in `AppDatabaseExpressInteropTests`.
    static let coinContractAddress = "0"

    // MARK: Providers cache

    static func makeFullProviderRecord(id: String, type: String) -> ExpressProviderRecord {
        ExpressProviderRecord(
            id: id,
            name: id.capitalized,
            type: type,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: "https://example.com/\(id).png",
            termsOfUse: "https://example.com/terms",
            privacyPolicy: "https://example.com/privacy",
            recommended: true,
            slippage: "1.5",
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    static func makeMinimalProviderRecord(id: String, type: String) -> ExpressProviderRecord {
        ExpressProviderRecord(
            id: id,
            name: id.capitalized,
            type: type,
            exchangeOnlyWithinSingleAddress: true,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Fiat currencies cache

    static func makeFullFiatCurrencyRecord() -> FiatCurrencyRecord {
        FiatCurrencyRecord(
            code: "USD",
            name: "United States Dollar",
            imageURL: "https://example.com/usd.png",
            precision: 2,
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    static func makeMinimalFiatCurrencyRecord() -> FiatCurrencyRecord {
        FiatCurrencyRecord(
            code: "USD",
            name: "United States Dollar",
            imageURL: nil,
            precision: 2,
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Crypto currencies cache

    static func makeFullCryptoCurrencyRecord(networkID: String, contractAddress: String) -> CryptoCurrencyRecord {
        CryptoCurrencyRecord(
            id: "token-id",
            networkID: networkID,
            name: "Token",
            symbol: "TKN",
            contractAddress: contractAddress,
            decimalCount: 6,
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    static func makeMinimalCryptoCurrencyRecord(networkID: String, contractAddress: String) -> CryptoCurrencyRecord {
        CryptoCurrencyRecord(
            id: nil,
            networkID: networkID,
            name: "Coin",
            symbol: "COIN",
            contractAddress: contractAddress,
            decimalCount: 18,
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Exchange transactions

    static func makeFullExchangeTransactionRecord(
        id: String,
        providerID: String,
        fromNetwork: String,
        fromContract: String,
        toNetwork: String,
        toContract: String,
        refundNetwork: String?,
        refundContractAddress: String?
    ) -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: id,
            ownerAddress: "0xOwner",
            providerID: providerID,
            fromAddress: "0xFrom",
            payInAddress: "0xPayIn",
            payInExtraId: "pay-in-extra-1",
            payOutAddress: "0xPayOut",
            status: "failed",
            rateType: "float",
            externalTxID: "external-tx-1",
            externalTxURL: "https://example.com/tx/external-tx-1",
            payInHash: "0xPayInHash",
            payOutHash: "0xPayOutHash",
            fromNetwork: fromNetwork,
            fromContract: fromContract,
            fromAmount: "100.5",
            fromDecimals: 6,
            fromActualAmount: "100.4",
            toNetwork: toNetwork,
            toContract: toContract,
            toAmount: "0.002",
            toDecimals: 8,
            toActualAmount: "0.0019",
            refundAddress: "0xRefund",
            refundExtraId: "refund-extra-1",
            refundNetwork: refundNetwork,
            refundContractAddress: refundContractAddress,
            createdAt: Date(timeIntervalSince1970: 1_752_000_000.125),
            updatedAt: Date(timeIntervalSince1970: 1_752_003_600.5)
        )
    }

    static func makeMinimalExchangeTransactionRecord() -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: "exchange-tx-1",
            ownerAddress: "0xOwner",
            providerID: "changelly",
            fromAddress: nil,
            payInAddress: "0xPayIn",
            payInExtraId: nil,
            payOutAddress: "0xPayOut",
            status: "waiting",
            rateType: nil,
            externalTxID: nil,
            externalTxURL: nil,
            payInHash: nil,
            payOutHash: nil,
            fromNetwork: "ethereum",
            fromContract: coinContractAddress,
            fromAmount: "0.1",
            fromDecimals: 18,
            fromActualAmount: nil,
            toNetwork: "bitcoin",
            toContract: coinContractAddress,
            toAmount: "0.002",
            toDecimals: 8,
            toActualAmount: nil,
            refundAddress: nil,
            refundExtraId: nil,
            refundNetwork: nil,
            refundContractAddress: nil,
            createdAt: Date(timeIntervalSince1970: 1_752_000_000.125),
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Onramp transactions

    static func makeFullOnrampTransactionRecord(
        id: String,
        providerID: String,
        fromCurrency: String,
        toNetwork: String,
        toContract: String
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
            toNetwork: toNetwork,
            toContract: toContract,
            toAmount: "249.5",
            toDecimals: 6,
            toActualAmount: "249.4",
            failReason: "provider-error",
            paymentMethod: "card",
            countryCode: "US",
            createdAt: Date(timeIntervalSince1970: 1_752_000_000.125),
            updatedAt: Date(timeIntervalSince1970: 1_752_003_600.5)
        )
    }

    static func makeMinimalOnrampTransactionRecord() -> ExpressOnrampTransactionRecord {
        ExpressOnrampTransactionRecord(
            id: "onramp-tx-1",
            ownerAddress: "0xOwner",
            providerID: "mercuryo",
            payOutAddress: "0xPayOut",
            status: "created",
            externalTxID: nil,
            externalTxURL: nil,
            payOutHash: nil,
            fromCurrency: "USD",
            fromAmount: "250",
            toNetwork: "ethereum",
            toContract: coinContractAddress,
            toAmount: nil,
            toDecimals: 18,
            toActualAmount: nil,
            failReason: nil,
            paymentMethod: "card",
            countryCode: "US",
            createdAt: Date(timeIntervalSince1970: 1_752_000_000.125),
            updatedAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Sync metadata

    static func makeFullSyncMetadataRecord(ownerAddress: String, endpointType: String) -> ExpressSyncMetadataRecord {
        ExpressSyncMetadataRecord(
            ownerAddress: ownerAddress,
            endpointType: endpointType,
            archiveCursor: "archive-cursor-1",
            deltaCursor: "delta-cursor-1",
            isInitialSyncDone: true,
            lastSyncAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    static func makeMinimalSyncMetadataRecord(ownerAddress: String, endpointType: String) -> ExpressSyncMetadataRecord {
        ExpressSyncMetadataRecord(
            ownerAddress: ownerAddress,
            endpointType: endpointType,
            archiveCursor: nil,
            deltaCursor: nil,
            isInitialSyncDone: false,
            lastSyncAt: Date(timeIntervalSince1970: 1_752_000_000.125)
        )
    }

    // MARK: Transaction history index

    static func makeHistoryIndexRecord(
        entityType: String,
        entityID: String,
        address: String,
        network: String,
        contract: String,
        dateTime: Date
    ) -> TransactionHistoryIndexRecord {
        TransactionHistoryIndexRecord(
            entityType: entityType,
            entityID: entityID,
            address: address,
            network: network,
            contract: contract,
            dateTime: dateTime
        )
    }
}

// MARK: - Expectations

func expectSameDatabaseRepresentation<Record: EncodableRecord>(
    _ fetchedRecord: Record,
    _ originalRecord: Record,
    sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let fetchedRepresentation = try fetchedRecord.databaseDictionary
    let originalRepresentation = try originalRecord.databaseDictionary

    #expect(fetchedRepresentation == originalRepresentation, sourceLocation: sourceLocation)
}
