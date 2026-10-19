//
//  ExpressSyncMetadataTable.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

enum ExpressSyncMetadataTable: AppDatabaseTable {
    static let tableName = "expressSyncMetadata"

    static func registerForVersion(
        _ version: AppDatabaseVersion,
        in database: Database,
        migrationHelper: AppDatabaseMigrationHelper
    ) throws {
        switch version {
        case .v1:
            try V1.register(in: database)
        case .v2:
            try V2.register(in: database)
        case .v3:
            try V3.register(in: database, migrationHelper: migrationHelper)
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

    enum V2 {
        static func register(in database: Database) throws {
            try database.alter(table: tableName) { table in
                table.rename(column: Columns.ownerAddress, to: Columns.userWalletID)
            }
        }
    }

    enum V3 {
        static func register(in database: Database, migrationHelper: AppDatabaseMigrationHelper) throws {
            try database.alter(table: tableName) { table in
                table.rename(column: Columns.userWalletID, to: Columns.walletID)
            }

            let storedWalletIDs = try SyncMetadataV2ToV3
                .select(\.walletID, as: String.self)
                .distinct()
                .fetchAll(database)

            for storedWalletID in storedWalletIDs {
                let migratedWalletID = migrationHelper.expressSyncMetadataV3WalletID(fromV2UserWalletID: storedWalletID)

                try SyncMetadataV2ToV3
                    .filter { $0.walletID == storedWalletID }
                    .updateAll(database, onConflict: .replace) { syncMetadata in
                        syncMetadata.walletID.set(to: migratedWalletID)
                    }
            }
        }
    }
}

// MARK: - Auxiliary types

private extension ExpressSyncMetadataTable.V3 {
    /// Transient type for the V2 to V3 migration only.
    /// GRDB migrations should not depend on the evolving public types, like `ExpressSyncMetadataRecord`.
    struct SyncMetadataV2ToV3: TableRecord {
        enum Columns {
            static let walletID = Column(ExpressSyncMetadataTable.Columns.walletID)
        }

        static let databaseTableName = ExpressSyncMetadataTable.tableName
    }
}

// MARK: - Columns

private extension ExpressSyncMetadataTable {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let ownerAddress = "ownerAddress"
        static let userWalletID = "userWalletID"
        static let walletID = "walletID"
        static let endpointType = "endpointType"
    }
}
