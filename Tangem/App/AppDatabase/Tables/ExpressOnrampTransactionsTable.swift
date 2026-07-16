//
//  ExpressOnrampTransactionsTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum ExpressOnrampTransactionsTable: AppDatabaseTable {
    static let tableName = "expressOnrampTransactions"

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension ExpressOnrampTransactionsTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column(Columns.ownerAddress, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("payOutAddress", .text)
                table.column("status", .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(Columns.payOutHash, .text)
                table.column("fromCurrency", .text).notNull()
                table.column("fromAmount", .text).notNull()
                table.column("fromDecimals", .integer)
                // 1. Can't be optional since it's part of the primary key (and NULLs are distinct in SQLite).
                // `ExpressConstants.coinContractAddress` is used for coins that don't have a contract address.
                // 2. Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Columns.toContract, .text).notNull().collate(.nocase)
                table.column(Columns.toNetwork, .text).notNull()
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxOnOwner",
                on: tableName,
                columns: [
                    Columns.ownerAddress,
                ]
            )

            try database.create(
                index: "idxOnPayOut",
                on: tableName,
                columns: [
                    Columns.payOutHash,
                ]
            )

            try database.create(
                index: "idxOnTokenFilter",
                on: tableName,
                columns: [
                    Columns.toNetwork,
                    Columns.toContract,
                    Columns.ownerAddress,
                ]
            )
        }
    }
}

// MARK: - Columns

private extension ExpressOnrampTransactionsTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let ownerAddress = "ownerAddress"
        static let payOutHash = "payOutHash"
        static let toNetwork = "toNetwork"
        static let toContract = "toContract"
    }
}
