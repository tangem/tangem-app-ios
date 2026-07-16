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

private extension ExpressExchangeTransactionsTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                table: Constants.tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column(Constants.ownerAddressColumnName, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("fromAddress", .text)
                table.column("payInAddress", .text)
                table.column("payOutAddress", .text)
                table.column(Constants.statusColumnName, .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(Constants.payInHashColumnName, .text)
                table.column(Constants.payOutHashColumnName, .text)
                table.column(Constants.fromContractColumnName, .text)
                table.column(Constants.fromNetworkColumnName, .text).notNull()
                table.column("fromAmount", .text).notNull()
                table.column("fromDecimals", .integer).notNull()
                table.column(Constants.toContractColumnName, .text)
                table.column(Constants.toNetworkColumnName, .text).notNull()
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column(Constants.refundAddressColumnName, .text)
                table.column(Constants.refundNetworkColumnName, .text)
                table.column(Constants.refundContractAddressColumnName, .text)
                table.column(Constants.createdAtColumnName, .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxExOwner",
                on: Constants.tableName,
                columns: [
                    Constants.ownerAddressColumnName,
                ]
            )

            try database.create(
                index: "idxExPayIn",
                on: Constants.tableName,
                columns: [
                    Constants.payInHashColumnName,
                ]
            )

            try database.create(
                index: "idxExPayOut",
                on: Constants.tableName,
                columns: [
                    Constants.payOutHashColumnName,
                ]
            )

            try database.create(
                index: "idxExFromToken",
                on: Constants.tableName,
                columns: [
                    Constants.fromNetworkColumnName,
                    Constants.fromContractColumnName,
                    Constants.ownerAddressColumnName,
                ]
            )

            try database.create(
                index: "idxExToToken",
                on: Constants.tableName,
                columns: [
                    Constants.toNetworkColumnName,
                    Constants.toContractColumnName,
                    Constants.ownerAddressColumnName,
                ]
            )

            try database.create(
                index: "idxExRefundMatching",
                on: Constants.tableName,
                columns: [
                    Constants.statusColumnName,
                    Constants.refundNetworkColumnName,
                    Constants.refundContractAddressColumnName,
                    Constants.refundAddressColumnName,
                    Constants.createdAtColumnName,
                ]
            )
        }
    }
}

// MARK: - Constants

extension ExpressExchangeTransactionsTable {
    /// - Note: only names used twice or more are extracted to constants.
    enum Constants {
        static let tableName = "expressExchangeTransactions"
        fileprivate static let ownerAddressColumnName = "ownerAddress"
        fileprivate static let payOutHashColumnName = "payOutHash"
        fileprivate static let payInHashColumnName = "payInHash"
        fileprivate static let fromNetworkColumnName = "fromNetwork"
        fileprivate static let fromContractColumnName = "fromContract"
        fileprivate static let toNetworkColumnName = "toNetwork"
        fileprivate static let toContractColumnName = "toContract"
        fileprivate static let statusColumnName = "status"
        fileprivate static let refundNetworkColumnName = "refundNetwork"
        fileprivate static let refundContractAddressColumnName = "refundContractAddress"
        fileprivate static let refundAddressColumnName = "refundAddress"
        fileprivate static let createdAtColumnName = "createdAt"
    }
}
