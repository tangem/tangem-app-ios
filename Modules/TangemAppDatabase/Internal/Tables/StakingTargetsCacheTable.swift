//
//  StakingTargetsCacheTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum StakingTargetsCacheTable: AppDatabaseTable {
    static let tableName = "stakingTargetsCache"

    static func registerForVersion(
        _ version: AppDatabaseVersion,
        in database: Database,
        migrationHelper: AppDatabaseMigrationHelper
    ) throws {
        switch version {
        case .v1:
            break
        case .v2:
            try V2.register(in: database)
        case .v3:
            break
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension StakingTargetsCacheTable {
    enum V2 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey([
                    Columns.networkID,
                    Columns.address,
                ])
                table.column(Columns.networkID, .text).notNull()
                table.column(Columns.address, .text).notNull()
                table.column("name", .text).notNull()
                table.column("updatedAt", .datetime).notNull()
            }
        }
    }
}

// MARK: - Columns

private extension StakingTargetsCacheTable {
    enum Columns {
        static let networkID = "networkID"
        static let address = "address"
    }
}
