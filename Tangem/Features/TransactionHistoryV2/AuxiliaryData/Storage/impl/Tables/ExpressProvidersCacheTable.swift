//
//  ExpressProvidersCacheTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum ExpressProvidersCacheTable: AppDatabaseTable {
    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.registerForVersion(version, in: database)
        case .v2:
            break
        }
    }
}

// MARK: - Individual table versions

private extension ExpressProvidersCacheTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                table: "expressProvidersCache",
                options: [
                    .ifNotExists,
                ]
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column("name", .text).notNull()
                table.column("imageURL", .text)
                table.column("updatedAt", .datetime).notNull()
            }
        }
    }
}
