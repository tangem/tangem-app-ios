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
    static let tableName = "expressSyncMetadata"

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        }
    }
}

// MARK: - Individual table versions (V1, V2, V3 and so on)

private extension ExpressSyncMetadataTable {
    enum V1 {
        static func register(in database: Database) throws {
            try database.create(
                table: tableName
            ) { table in
                table.primaryKey([
                    Columns.ownerAddress,
                    Columns.endpointType,
                ])
                table.column(Columns.ownerAddress, .text).notNull()
                table.column(Columns.endpointType, .text).notNull()
                table.column("archiveCursor", .text)
                table.column("deltaCursor", .text)
                table.column("isInitialSyncDone", .boolean).notNull().defaults(to: false)
                table.column("lastSyncAt", .datetime).notNull()
            }
        }
    }
}

// MARK: - Columns

private extension ExpressSyncMetadataTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let ownerAddress = "ownerAddress"
        static let endpointType = "endpointType"
    }
}
