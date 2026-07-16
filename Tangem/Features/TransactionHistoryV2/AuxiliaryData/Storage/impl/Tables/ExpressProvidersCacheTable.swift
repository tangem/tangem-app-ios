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

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension ExpressProvidersCacheTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                table: Constants.tableName
            ) { table in
                table.primaryKey("id", .text).notNull()
                table.column("name", .text).notNull()
                table.column("type", .text).notNull()
                table.column("exchangeOnlyWithinSingleAddress", .boolean).notNull()
                table.column("imageURL", .text)
                table.column("termsOfUse", .text)
                table.column("privacyPolicy", .text)
                table.column("recommended", .boolean)
                table.column("slippage", .text)
                table.column("updatedAt", .datetime).notNull()
            }
        }
    }
}

// MARK: - Constants

extension ExpressProvidersCacheTable {
    /// - Note: only names used twice or more are extracted to constants.
    enum Constants {
        static let tableName = "expressProvidersCache"
    }
}
