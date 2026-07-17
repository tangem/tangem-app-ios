//
//  CryptoCurrenciesCacheTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum CryptoCurrenciesCacheTable: AppDatabaseTable {
    static let tableName = "cryptoCurrenciesCache"

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension CryptoCurrenciesCacheTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey([
                    Columns.networkID,
                    Columns.contractAddress,
                ])
                // `id` can't be the primary key because a `BlockchainSdk.Token` may have no `id` field at all (e.g., custom tokens).
                table.column(Columns.id, .text)
                // Matches the `TokenItem.networkId` field.
                table.column(Columns.networkID, .text).notNull()
                table.column("name", .text).notNull()
                table.column("symbol", .text).notNull()
                // 1. Can't be optional since it's part of the primary key (and NULLs are distinct in SQLite).
                // `ExpressConstants.coinContractAddress` is used for coins that don't have a contract address.
                // 2. Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Columns.contractAddress, .text).notNull().collate(.nocase)
                table.column("decimalCount", .integer).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxCryptoCurrId",
                on: tableName,
                columns: [
                    Columns.id,
                ]
            )
        }
    }
}

// MARK: - Columns

private extension CryptoCurrenciesCacheTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let id = "id"
        static let networkID = "networkID"
        static let contractAddress = "contractAddress"
    }
}
