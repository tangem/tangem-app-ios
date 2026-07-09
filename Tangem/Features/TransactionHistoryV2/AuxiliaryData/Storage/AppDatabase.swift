//
//  AppDatabase.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

// [REDACTED_TODO_COMMENT]
final class AppDatabase {
    typealias DatabaseHandle = DatabaseReader & DatabaseWriter
    typealias DatabaseHandleFactory = (_ databaseFilePath: String) throws -> DatabaseHandle

    static let shared = AppDatabase { databaseFilePath in
        // [REDACTED_TODO_COMMENT]
        return try DatabaseQueue(path: databaseFilePath)
    }

    let databaseHandle: DatabaseHandle

    private init(databaseHandleFactory: @escaping DatabaseHandleFactory) {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        databaseHandle = try! Self.makeDatabaseHandle(using: databaseHandleFactory)
    }

    // MARK: - Factory methods

    private static func makeDatabaseHandle(using databaseHandleFactory: DatabaseHandleFactory) throws -> DatabaseHandle {
        let databasePath = try makeDatabaseFilePath()
        let migrator = makeDatabaseMigrator()
        let databaseHandle = try databaseHandleFactory(databasePath)

        try migrator.migrate(databaseHandle)

        return databaseHandle
    }

    private static func makeDatabaseFilePath() throws -> String {
        let fileManager = FileManager.default

        let applicationSupportDirectoryURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let databaseDirectoryURL = applicationSupportDirectoryURL.appendingPathComponent(
            Constants.databaseDirectoryName,
            isDirectory: true
        )

        try fileManager.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: true)

        let databaseURL = databaseDirectoryURL.appending(path: Constants.databaseFileName, directoryHint: .notDirectory)

        return databaseURL.path
    }

    private static func makeDatabaseMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { database in
            try database.create(table: "expressProviders", options: [.ifNotExists, .strict]) { table in
                table.primaryKey("id", .text, onConflict: .replace).notNull()
                table.column("name", .text).notNull()
                table.column("imageURL", .text)
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(table: "expressSyncMetadata", options: [.ifNotExists, .strict]) { table in
                let ownerAddressColumnName = "ownerAddress"
                let endpointTypeColumnName = "endpointType"
                table.primaryKey([ownerAddressColumnName, endpointTypeColumnName], onConflict: .replace)
                table.column(ownerAddressColumnName, .text).notNull()
                table.column(endpointTypeColumnName, .text).notNull()
                table.column("archiveCursor", .text)
                table.column("deltaCursor", .text)
                table.column("isInitialSyncDone", .boolean).notNull().defaults(to: false)
                table.column("lastSyncAt", .datetime).notNull()
            }

            let expressOnrampTransactionsTableName = "expressOnrampTransactions"
            let ownerAddressColumnName = "ownerAddress"
            let payOutHashColumnName = "payOutHash"
            let toNetworkColumnName = "toNetwork"
            let toContractColumnName = "toContract"

            try database.create(table: expressOnrampTransactionsTableName, options: [.ifNotExists, .strict]) { table in
                table.primaryKey("id", .text, onConflict: .replace).notNull()
                table.column(ownerAddressColumnName, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("payOutAddress", .text)
                table.column("status", .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(payOutHashColumnName, .text)
                table.column("fromCurrency", .text).notNull()
                table.column("fromAmount", .text).notNull()
                table.column("fromDecimals", .integer)
                table.column(toContractColumnName, .text)
                table.column(toNetworkColumnName, .text).notNull()
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxOnOwner",
                on: expressOnrampTransactionsTableName,
                columns: [
                    ownerAddressColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxOnPayOut",
                on: expressOnrampTransactionsTableName,
                columns: [
                    payOutHashColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxOnTokenFilter",
                on: expressOnrampTransactionsTableName,
                columns: [
                    toNetworkColumnName,
                    toContractColumnName,
                    ownerAddressColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            let expressExchangeTransactionsTableName = "expressExchangeTransactions"
            let payInHashColumnName = "payInHash"
            let fromNetworkColumnName = "fromNetwork"
            let fromContractColumnName = "fromContract"
            let statusColumnName = "status"
            let refundNetworkColumnName = "refundNetwork"
            let refundContractAddressColumnName = "refundContractAddress"
            let refundAddressColumnName = "refundAddress"
            let createdAtColumnName = "createdAt"

            try database.create(table: expressExchangeTransactionsTableName, options: [.ifNotExists, .strict]) { table in
                table.primaryKey("id", .text, onConflict: .replace).notNull()
                table.column(ownerAddressColumnName, .text).notNull()
                table.column("providerID", .text).notNull()
                table.column("fromAddress", .text)
                table.column("payInAddress", .text)
                table.column("payOutAddress", .text)
                table.column(statusColumnName, .text).notNull()
                table.column("externalTxID", .text)
                table.column("externalTxURL", .text)
                table.column(payInHashColumnName, .text)
                table.column(payOutHashColumnName, .text)
                table.column(fromContractColumnName, .text)
                table.column(fromNetworkColumnName, .text).notNull()
                table.column("fromDecimals", .integer).notNull()
                table.column(toContractColumnName, .text)
                table.column(toNetworkColumnName, .text).notNull()
                table.column("toAmount", .text).notNull()
                table.column("toDecimals", .integer).notNull()
                table.column("toActualAmount", .text)
                table.column("failReason", .text)
                table.column(refundAddressColumnName, .text)
                table.column(refundNetworkColumnName, .text)
                table.column(refundContractAddressColumnName, .text)
                table.column(createdAtColumnName, .datetime).notNull()
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(
                index: "idxOnOwner",
                on: expressExchangeTransactionsTableName,
                columns: [
                    ownerAddressColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxExPayIn",
                on: expressExchangeTransactionsTableName,
                columns: [
                    payInHashColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxExPayOut",
                on: expressExchangeTransactionsTableName,
                columns: [
                    payOutHashColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxExFromToken",
                on: expressExchangeTransactionsTableName,
                columns: [
                    fromNetworkColumnName,
                    fromContractColumnName,
                    ownerAddressColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxExToToken",
                on: expressExchangeTransactionsTableName,
                columns: [
                    toNetworkColumnName,
                    toContractColumnName,
                    ownerAddressColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )

            try database.create(
                index: "idxExRefundMatching",
                on: expressExchangeTransactionsTableName,
                columns: [
                    statusColumnName,
                    refundNetworkColumnName,
                    refundContractAddressColumnName,
                    refundAddressColumnName,
                    createdAtColumnName,
                ],
                options: [
                    .ifNotExists,
                ]
            )
        }

        return migrator
    }
}

// MARK: - Constants

private extension AppDatabase {
    enum Constants {
        static let databaseDirectoryName = "AppDatabase"
        static let databaseFileName = "db.sqlite"
    }
}
