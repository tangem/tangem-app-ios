//
//  FiatCurrenciesCacheTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum FiatCurrenciesCacheTable: AppDatabaseTable {
    static let tableName = "fiatCurrenciesCache"

    static func registerForVersion(
        _ version: AppDatabaseVersion,
        in database: Database,
        migrationHelper: AppDatabaseMigrationHelper
    ) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        case .v2:
            break
        case .v3:
            break
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension FiatCurrenciesCacheTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey("code", .text).notNull()
                table.column("name", .text).notNull()
                table.column("imageURL", .text)
                table.column("precision", .integer).notNull()
                table.column("updatedAt", .datetime).notNull()
            }
        }
    }
}
