//
//  ExpressExchangeTransactionsTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum ExpressExchangeTransactionsTable: AppDatabaseTable {
    static let tableName = "expressExchangeTransactions"

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension ExpressExchangeTransactionsTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column(Columns.ownerAddress, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("fromAddress", .text)
                table.column("payInAddress", .text)
                table.column("payOutAddress", .text)
                table.column(Columns.status, .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(Columns.payInHash, .text)
                table.column(Columns.payOutHash, .text)
                table.column(Columns.fromNetwork, .text).notNull()
                // Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Columns.fromContract, .text).notNull().collate(.nocase)
                table.column("fromAmount", .text).notNull()
                table.column("fromDecimals", .integer).notNull()
                table.column(Columns.toNetwork, .text).notNull()
                // Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Columns.toContract, .text).notNull().collate(.nocase)
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column(Columns.refundAddress, .text)
                table.column(Columns.refundNetwork, .text)
                // Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Columns.refundContractAddress, .text).collate(.nocase)
                table.column(Columns.createdAt, .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxExOwner",
                on: tableName,
                columns: [
                    Columns.ownerAddress,
                ]
            )

            try database.create(
                index: "idxExPayIn",
                on: tableName,
                columns: [
                    Columns.payInHash,
                ]
            )

            try database.create(
                index: "idxExPayOut",
                on: tableName,
                columns: [
                    Columns.payOutHash,
                ]
            )

            try database.create(
                index: "idxExFromToken",
                on: tableName,
                columns: [
                    Columns.fromNetwork,
                    Columns.fromContract,
                    Columns.ownerAddress,
                ]
            )

            try database.create(
                index: "idxExToToken",
                on: tableName,
                columns: [
                    Columns.toNetwork,
                    Columns.toContract,
                    Columns.ownerAddress,
                ]
            )

            try database.create(
                index: "idxExRefundMatching",
                on: tableName,
                columns: [
                    Columns.status,
                    Columns.refundNetwork,
                    Columns.refundContractAddress,
                    Columns.refundAddress,
                    Columns.createdAt,
                ]
            )
        }
    }
}

// MARK: - Columns

private extension ExpressExchangeTransactionsTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let ownerAddress = "ownerAddress"
        static let payOutHash = "payOutHash"
        static let payInHash = "payInHash"
        static let fromNetwork = "fromNetwork"
        static let fromContract = "fromContract"
        static let toNetwork = "toNetwork"
        static let toContract = "toContract"
        static let status = "status"
        static let refundNetwork = "refundNetwork"
        static let refundContractAddress = "refundContractAddress"
        static let refundAddress = "refundAddress"
        static let createdAt = "createdAt"
    }
}
