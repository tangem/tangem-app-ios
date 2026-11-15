//
//  JointOperationsTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum JointOperationsTable: AppDatabaseTable {
    static let tableName = "jointOperations"

    static func registerForVersion(
        _ version: AppDatabaseVersion,
        in database: Database,
        migrationHelper: AppDatabaseMigrationHelper
    ) throws {
        switch version {
        case .v1, .v2, .v3:
            break
        case .v4:
            try V4.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension JointOperationsTable {
    enum V4 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column("cryptoAccountID", .text).notNull()
                table.column("safeAddress", .text).notNull()
                table.column("chainID", .integer).notNull()
                table.column("status", .text).notNull()
                table.column("initiator", .text).notNull()
                table.column("to", .text).notNull()
                table.column("value", .text).notNull()
                table.column("data", .text).notNull()
                table.column("operation", .integer).notNull()
                table.column("safeTxGas", .text).notNull()
                table.column("baseGas", .text).notNull()
                table.column("gasPrice", .text).notNull()
                table.column("gasToken", .text).notNull()
                table.column("refundReceiver", .text).notNull()
                table.column("nonce", .integer).notNull()
                table.column("threshold", .integer).notNull()
                table.column("txHash", .text)
                table.column("cancelReason", .text)
                table.column("signatures", .text).notNull()
                table.column("createdAt", .datetime).notNull()
                table.column("finishedAt", .datetime)
            }
        }
    }
}
