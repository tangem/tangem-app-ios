//
//  ExpressExchangeTransactionRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct ExpressExchangeTransactionRecord {
    public let id: String
    public let ownerAddress: String
    public let providerID: String
    public let fromAddress: String?
    public let payInAddress: String
    public let payInExtraId: String?
    public let payOutAddress: String
    public let status: String
    public let rateType: String?
    public let externalTxID: String?
    public let externalTxURL: String?
    public let payInHash: String?
    public let payOutHash: String?
    public let fromNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let fromContract: String
    /// - Note: Actually a decimal number.
    public let fromAmount: String
    public let fromDecimals: Int
    /// - Note: Actually a decimal number.
    public let fromActualAmount: String?
    public let toNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let toContract: String
    /// - Note: Actually a decimal number.
    public let toAmount: String
    public let toDecimals: Int
    /// - Note: Actually a decimal number.
    public let toActualAmount: String?
    public let refundAddress: String?
    public let refundExtraId: String?
    public let refundNetwork: String?
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let refundContractAddress: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        ownerAddress: String,
        providerID: String,
        fromAddress: String?,
        payInAddress: String,
        payInExtraId: String?,
        payOutAddress: String,
        status: String,
        rateType: String?,
        externalTxID: String?,
        externalTxURL: String?,
        payInHash: String?,
        payOutHash: String?,
        fromNetwork: String,
        fromContract: String,
        fromAmount: String,
        fromDecimals: Int,
        fromActualAmount: String?,
        toNetwork: String,
        toContract: String,
        toAmount: String,
        toDecimals: Int,
        toActualAmount: String?,
        refundAddress: String?,
        refundExtraId: String?,
        refundNetwork: String?,
        refundContractAddress: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.ownerAddress = ownerAddress
        self.providerID = providerID
        self.fromAddress = fromAddress
        self.payInAddress = payInAddress
        self.payInExtraId = payInExtraId
        self.payOutAddress = payOutAddress
        self.status = status
        self.rateType = rateType
        self.externalTxID = externalTxID
        self.externalTxURL = externalTxURL
        self.payInHash = payInHash
        self.payOutHash = payOutHash
        self.fromNetwork = fromNetwork
        self.fromContract = fromContract
        self.fromAmount = fromAmount
        self.fromDecimals = fromDecimals
        self.fromActualAmount = fromActualAmount
        self.toNetwork = toNetwork
        self.toContract = toContract
        self.toAmount = toAmount
        self.toDecimals = toDecimals
        self.toActualAmount = toActualAmount
        self.refundAddress = refundAddress
        self.refundExtraId = refundExtraId
        self.refundNetwork = refundNetwork
        self.refundContractAddress = refundContractAddress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Fetching helpers

public extension ExpressExchangeTransactionRecord {
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
    .filter(ExpressProviderRecord.Values.ProviderType.swap.contains(ExpressProviderRecord.Columns.type))

    static let fromCryptoCurrency = belongsTo(
        CryptoCurrencyRecord.self,
        key: "fromCryptoCurrency",
        using: ForeignKey([
            Columns.fromNetwork,
            Columns.fromContract,
        ], to: [
            CryptoCurrencyRecord.Columns.networkID,
            CryptoCurrencyRecord.Columns.contractAddress,
        ])
    )

    static let toCryptoCurrency = belongsTo(
        CryptoCurrencyRecord.self,
        key: "toCryptoCurrency",
        using: ForeignKey([
            Columns.toNetwork,
            Columns.toContract,
        ], to: [
            CryptoCurrencyRecord.Columns.networkID,
            CryptoCurrencyRecord.Columns.contractAddress,
        ])
    )

    static let refundCryptoCurrency = belongsTo(
        CryptoCurrencyRecord.self,
        key: "refundCryptoCurrency",
        using: ForeignKey([
            Columns.refundNetwork,
            Columns.refundContractAddress,
        ], to: [
            CryptoCurrencyRecord.Columns.networkID,
            CryptoCurrencyRecord.Columns.contractAddress,
        ])
    )

    static let historyIndexRecords = hasMany(
        TransactionHistoryIndexRecord.self,
        key: "historyIndexRecords",
        using: TransactionHistoryIndexRecord.expressEntityForeignKey
    )
}

// MARK: - Identifiable protocol conformance

extension ExpressExchangeTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressExchangeTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressExchangeTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressExchangeTransactionRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let providerID = Column(CodingKeys.providerID)
        public static let fromNetwork = Column(CodingKeys.fromNetwork)
        public static let fromContract = Column(CodingKeys.fromContract)
        public static let toNetwork = Column(CodingKeys.toNetwork)
        public static let toContract = Column(CodingKeys.toContract)
        public static let refundNetwork = Column(CodingKeys.refundNetwork)
        public static let refundContractAddress = Column(CodingKeys.refundContractAddress)
    }

    public static let databaseTableName = ExpressExchangeTransactionsTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressExchangeTransactionRecord: PersistableRecord {}
