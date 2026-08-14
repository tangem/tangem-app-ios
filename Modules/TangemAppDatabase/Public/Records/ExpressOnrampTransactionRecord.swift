//
//  ExpressOnrampTransactionRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct ExpressOnrampTransactionRecord {
    public let id: String
    public let ownerAddress: String
    public let providerID: String
    public let payOutAddress: String
    public let status: String
    public let externalTxID: String?
    public let externalTxURL: String?
    public let payOutHash: String?
    public let fromCurrency: String
    /// - Note: Actually a decimal number.
    public let fromAmount: String
    public let toNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let toContract: String
    /// - Note: Actually a decimal number.
    public let toAmount: String?
    public let toDecimals: Int
    /// - Note: Actually a decimal number.
    public let toActualAmount: String?
    public let failReason: String?
    public let paymentMethod: String
    public let countryCode: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        ownerAddress: String,
        providerID: String,
        payOutAddress: String,
        status: String,
        externalTxID: String?,
        externalTxURL: String?,
        payOutHash: String?,
        fromCurrency: String,
        fromAmount: String,
        toNetwork: String,
        toContract: String,
        toAmount: String?,
        toDecimals: Int,
        toActualAmount: String?,
        failReason: String?,
        paymentMethod: String,
        countryCode: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.ownerAddress = ownerAddress
        self.providerID = providerID
        self.payOutAddress = payOutAddress
        self.status = status
        self.externalTxID = externalTxID
        self.externalTxURL = externalTxURL
        self.payOutHash = payOutHash
        self.fromCurrency = fromCurrency
        self.fromAmount = fromAmount
        self.toNetwork = toNetwork
        self.toContract = toContract
        self.toAmount = toAmount
        self.toDecimals = toDecimals
        self.toActualAmount = toActualAmount
        self.failReason = failReason
        self.paymentMethod = paymentMethod
        self.countryCode = countryCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Fetching helpers

public extension ExpressOnrampTransactionRecord {
    static let provider = belongsTo(
        ExpressProviderRecord.self,
        key: "provider",
        using: ForeignKey([
            Columns.providerID,
        ], to: [
            ExpressProviderRecord.Columns.id,
        ])
    )
    // Additional filtering needed since Express providers have composite pkeys `(id, type)`, but we can join on `id` only
    .filter(ExpressProviderRecord.Values.ProviderType.onramp.contains(ExpressProviderRecord.Columns.type))

    static let fiatCurrency = belongsTo(
        FiatCurrencyRecord.self,
        key: "fiatCurrency",
        using: ForeignKey([
            Columns.fromCurrency,
        ], to: [
            // Can be dropped since `code` is a primary key of `FiatCurrencyRecord`, but kept here for clarity
            FiatCurrencyRecord.Columns.code,
        ])
    )

    static let cryptoCurrency = belongsTo(
        CryptoCurrencyRecord.self,
        key: "cryptoCurrency",
        using: ForeignKey([
            Columns.toNetwork,
            Columns.toContract,
        ], to: [
            CryptoCurrencyRecord.Columns.networkID,
            CryptoCurrencyRecord.Columns.contractAddress,
        ])
    )

    static let historyIndexRecords = hasMany(
        TransactionHistoryIndexRecord.self,
        key: "historyIndexRecords",
        using: TransactionHistoryIndexRecord.onrampEntityForeignKey
    )
}

// MARK: - Identifiable protocol conformance

extension ExpressOnrampTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressOnrampTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressOnrampTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressOnrampTransactionRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let providerID = Column(CodingKeys.providerID)
        public static let fromCurrency = Column(CodingKeys.fromCurrency)
        public static let toNetwork = Column(CodingKeys.toNetwork)
        public static let toContract = Column(CodingKeys.toContract)
    }

    public static let databaseTableName = ExpressOnrampTransactionsTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressOnrampTransactionRecord: PersistableRecord {}
