//
//  ExpressOnrampTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressOnrampTransactionRecord {
    let id: String
    let ownerAddress: String
    let providerID: String
    let payOutAddress: String?
    let status: String
    let externalTxID: String?
    let externalTxURL: String?
    let payOutHash: String?
    let fromCurrency: String
    /// - Note: Actually a decimal number.
    let fromAmount: String
    let fromDecimals: Int?
    let toNetwork: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    let toContract: String
    /// - Note: Actually a decimal number.
    let toAmount: String
    let toDecimals: Int
    /// - Note: Actually a decimal number.
    let toActualAmount: String?
    let failReason: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Columns

extension ExpressOnrampTransactionRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let providerID = Column(CodingKeys.providerID)
        static let fromCurrency = Column(CodingKeys.fromCurrency)
        static let toNetwork = Column(CodingKeys.toNetwork)
        static let toContract = Column(CodingKeys.toContract)
    }
}

// MARK: - Identifiable protocol conformance

extension ExpressOnrampTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressOnrampTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressOnrampTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressOnrampTransactionRecord: TableRecord {
    static let databaseTableName = ExpressOnrampTransactionsTable.tableName

    static let provider = belongsTo(
        ExpressProviderRecord.self,
        key: "provider",
        using: ForeignKey([
            Columns.providerID,
        ], to: [
            // Can be dropped since `id` is a primary key of `ExpressProviderRecord`, but kept here for clarity
            ExpressProviderRecord.Columns.id,
        ]),
    )

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
}

// MARK: - PersistableRecord protocol conformance

extension ExpressOnrampTransactionRecord: PersistableRecord {}
