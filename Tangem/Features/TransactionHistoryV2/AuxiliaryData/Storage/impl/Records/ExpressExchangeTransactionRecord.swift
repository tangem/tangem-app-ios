//
//  ExpressExchangeTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressExchangeTransactionRecord {
    let id: String
    let ownerAddress: String
    let providerID: String
    let fromAddress: String?
    let payInAddress: String?
    let payOutAddress: String?
    let status: String
    let externalTxID: String?
    let externalTxURL: String?
    let payInHash: String?
    let payOutHash: String?
    let fromNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    let fromContract: String
    /// - Note: Actually a decimal number.
    let fromAmount: String
    let fromDecimals: Int
    let toNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    let toContract: String
    /// - Note: Actually a decimal number.
    let toAmount: String
    let toDecimals: Int
    /// - Note: Actually a decimal number.
    let toActualAmount: String?
    let failReason: String?
    let refundAddress: String?
    let refundNetwork: String?
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    let refundContractAddress: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Columns

extension ExpressExchangeTransactionRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let providerID = Column(CodingKeys.providerID)
        static let fromNetwork = Column(CodingKeys.fromNetwork)
        static let fromContract = Column(CodingKeys.fromContract)
        static let toNetwork = Column(CodingKeys.toNetwork)
        static let toContract = Column(CodingKeys.toContract)
    }
}

// MARK: - Identifiable protocol conformance

extension ExpressExchangeTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressExchangeTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressExchangeTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressExchangeTransactionRecord: TableRecord {
    static let databaseTableName = ExpressExchangeTransactionsTable.tableName

    static let provider = belongsTo(
        ExpressProviderRecord.self,
        key: "provider",
        using: ForeignKey([
            Columns.providerID,
        ], to: [
            ExpressProviderRecord.Columns.id,
        ])
    )

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
}

// MARK: - PersistableRecord protocol conformance

extension ExpressExchangeTransactionRecord: PersistableRecord {}
