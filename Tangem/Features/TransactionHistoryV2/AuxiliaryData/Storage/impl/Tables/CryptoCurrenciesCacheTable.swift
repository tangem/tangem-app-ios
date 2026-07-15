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
    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.registerForVersion(version, in: database)
        case .v2:
            break
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension CryptoCurrenciesCacheTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                options: [
                    .ifNotExists,
                ]
                table: Constants.tableName
            ) { table in
                table.primaryKey([
                    Constants.networkIDColumnName,
                    Constants.contractAddressColumnName,
                ])
                // `id` MUST NOT not be the primary key because a `BlockchainSdk.Token` may have no `id` field at all (e.g., custom tokens).
                table.column(Constants.idColumnName, .text)
                // Matches the `TokenItem.networkId` field.
                table.column(Constants.networkIDColumnName, .text).notNull()
                table.column("name", .text).notNull()
                table.column("symbol", .text).notNull()
                // 1. Can't be optional since it's part of the primary key (and NULLs are distinct in SQLite).
                // `ExpressConstants.coinContractAddress` is used for coins that don't have a contract address.
                // 2. Collation is used to make the contract address case-insensitive.
                // This matches the current `BlockchainSdk.Token` equality implementation.
                table.column(Constants.contractAddressColumnName, .text).notNull().collate(.nocase)
                table.column("decimalCount", .integer).notNull()
            }

            try database.create(
                index: "idxCryptoCurrId",
                on: Constants.tableName,
                columns: [
                    Constants.idColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )
        }
    }
}

// MARK: - Constants

extension CryptoCurrenciesCacheTable {
    /// - Note: only names used twice or more are extracted to constants.
    enum Constants {
        static let tableName = "cryptoCurrenciesCache"
        fileprivate static let idColumnName = "id"
        fileprivate static let networkIDColumnName = "networkID"
        fileprivate static let contractAddressColumnName = "contractAddress"
    }
}
