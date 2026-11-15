//
//  JointOperationsSyncMetadataTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum JointOperationsSyncMetadataTable: AppDatabaseTable {
    static let tableName = "jointOperationsSyncMetadata"

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

private extension JointOperationsSyncMetadataTable {
    enum V4 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey("walletID", .text).notNull()
                table.column("archiveCursor", .text)
                table.column("deltaCursor", .text)
                table.column("isInitialSyncDone", .boolean).notNull().defaults(to: false)
                table.column("lastSyncAt", .datetime).notNull()
            }
        }
    }
}
