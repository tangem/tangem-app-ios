//
//  TransactionHistoryIndexTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum TransactionHistoryIndexTable: AppDatabaseTable {
    static let tableName = "transactionHistoryIndex"

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension TransactionHistoryIndexTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName,
            ) { table in
                table.primaryKey([
                    Columns.entityType,
                    Columns.entityID,
                    Columns.ownerAddress,
                ])
                table.column(Columns.entityType, .text).notNull()
                table.column(Columns.entityID, .text).notNull()
                table.column(Columns.ownerAddress, .text).notNull()
                table.column(Columns.dateTime, .datetime).notNull()
            }

            try database.create(
                indexOn: tableName,
                columns: [
                    Columns.ownerAddress,
                    Columns.dateTime,
                    Columns.entityID,
                ]
            )
        }
    }
}

// MARK: - Columns

private extension TransactionHistoryIndexTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let entityType = "entityType"
        static let entityID = "entityID"
        static let ownerAddress = "ownerAddress"
        static let dateTime = "dateTime"
    }
}
