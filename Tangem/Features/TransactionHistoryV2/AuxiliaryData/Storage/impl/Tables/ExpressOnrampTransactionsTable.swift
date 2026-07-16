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

private extension ExpressOnrampTransactionsTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                table: Constants.tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column(Constants.ownerAddressColumnName, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("payOutAddress", .text)
                table.column("status", .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(Constants.payOutHashColumnName, .text)
                table.column("fromCurrency", .text).notNull()
                table.column("fromAmount", .text).notNull()
                table.column("fromDecimals", .integer)
                table.column(Constants.toContractColumnName, .text)
                table.column(Constants.toNetworkColumnName, .text).notNull()
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxOnOwner",
                on: Constants.tableName,
                columns: [
                    Constants.ownerAddressColumnName,
                ]
            )

            try database.create(
                index: "idxOnPayOut",
                on: Constants.tableName,
                columns: [
                    Constants.payOutHashColumnName,
                ]
            )

            try database.create(
                index: "idxOnTokenFilter",
                on: Constants.tableName,
                columns: [
                    Constants.toNetworkColumnName,
                    Constants.toContractColumnName,
                    Constants.ownerAddressColumnName,
                ]
            )
        }
    }
}

// MARK: - Constants

extension ExpressOnrampTransactionsTable {
    /// - Note: only names used twice or more are extracted to constants.
    enum Constants {
        static let tableName = "expressOnrampTransactions"
        fileprivate static let ownerAddressColumnName = "ownerAddress"
        fileprivate static let payOutHashColumnName = "payOutHash"
        fileprivate static let toNetworkColumnName = "toNetwork"
        fileprivate static let toContractColumnName = "toContract"
    }
}
