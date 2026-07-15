//
//  ExpressSyncMetadataTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum ExpressSyncMetadataTable: AppDatabaseTable {
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

private extension ExpressSyncMetadataTable {
    enum V1: AppDatabaseTable {
        static func registerForVersion(_: AppDatabaseVersion, in database: Database) throws {
            try database.create(
                table: "expressSyncMetadata"
            ) { table in
                table.primaryKey([
                    Constants.ownerAddressColumnName,
                    Constants.endpointTypeColumnName,
                ])
                table.column(Constants.ownerAddressColumnName, .text).notNull()
                table.column(Constants.endpointTypeColumnName, .text).notNull()
                table.column("archiveCursor", .text)
                table.column("deltaCursor", .text)
                table.column("isInitialSyncDone", .boolean).notNull().defaults(to: false)
                table.column("lastSyncAt", .datetime).notNull()
            }
        }
    }
}

// MARK: - Constants

private extension ExpressSyncMetadataTable {
    /// - Note: only names used twice or more are extracted to constants.
    enum Constants {
        static let ownerAddressColumnName = "ownerAddress"
        static let endpointTypeColumnName = "endpointType"
    }
}
