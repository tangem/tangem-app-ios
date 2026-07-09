//
//  AppDatabase.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

// [REDACTED_TODO_COMMENT]
final class AppDatabase {
    typealias DatabaseHandle = DatabaseReader & DatabaseWriter
    typealias DatabaseHandleFactory = (_ databaseFilePath: String) throws -> DatabaseHandle

    static let shared = AppDatabase { databaseFilePath in
        // [REDACTED_TODO_COMMENT]
        return try DatabaseQueue(path: databaseFilePath)
    }

    let databaseHandle: DatabaseHandle

    private init(databaseHandleFactory: @escaping DatabaseHandleFactory) {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        databaseHandle = try! Self.makeDatabaseHandle(using: databaseHandleFactory)
    }

    // MARK: - Factory methods

    private static func makeDatabaseHandle(using databaseHandleFactory: DatabaseHandleFactory) throws -> DatabaseHandle {
        let databasePath = try makeDatabaseFilePath()
        let migrator = makeDatabaseMigrator()
        let databaseHandle = try databaseHandleFactory(databasePath)

        try migrator.migrate(databaseHandle)

        return databaseHandle
    }

    private static func makeDatabaseFilePath() throws -> String {
        let fileManager = FileManager.default

        let applicationSupportDirectoryURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let databaseDirectoryURL = applicationSupportDirectoryURL.appendingPathComponent(
            Constants.databaseDirectoryName,
            isDirectory: true
        )

        try fileManager.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: true)

        let databaseURL = databaseDirectoryURL.appending(path: Constants.databaseFileName, directoryHint: .notDirectory)

        return databaseURL.path
    }

    private static func makeDatabaseMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { database in
            try database.create(table: "expressProviders", options: [.ifNotExists, .strict]) { table in
                table.primaryKey("id", .text, onConflict: .replace).notNull()
                table.column("name", .text).notNull()
                table.column("imageURL", .text)
                table.column("updatedAt", .datetime).notNull()
            }

            try database.create(table: "expressSyncMetadata", options: [.ifNotExists, .strict]) { table in
                let ownerAddressColumnName = "ownerAddress"
                let endpointTypeColumnName = "endpointType"
                table.primaryKey([ownerAddressColumnName, endpointTypeColumnName], onConflict: .replace)
                table.column(ownerAddressColumnName, .text).notNull()
                table.column(endpointTypeColumnName, .text).notNull()
                table.column("archiveCursor", .text)
                table.column("deltaCursor", .text)
                table.column("isInitialSyncDone", .boolean).notNull().defaults(to: false)
                table.column("lastSyncAt", .datetime).notNull()
            }
        }

        return migrator
    }
}

// MARK: - Constants

private extension AppDatabase {
    enum Constants {
        static let databaseDirectoryName = "AppDatabase"
        static let databaseFileName = "db.sqlite"
    }
}
