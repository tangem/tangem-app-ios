//
//  AppDatabase.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final class AppDatabase {
    typealias DatabaseHandle = DatabaseReader & DatabaseWriter
    typealias DatabaseHandleFactory = (_ databaseFilePath: String) throws -> DatabaseHandle

    static let shared = AppDatabase { databaseFilePath in
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        return try DatabaseQueue(path: databaseFilePath)
    }

    var databaseHandle: DatabaseHandle {
        get throws {
            return try protectedDatabaseHandle { handle in
                if let existingHandle = handle {
                    return existingHandle
                }

                let newHandle = try Self.makeDatabaseHandle(using: databaseHandleFactory)
                handle = newHandle

                return newHandle
            }
        }
    }

    private let protectedDatabaseHandle: OSAllocatedUnfairLock<DatabaseHandle?>
    private let databaseHandleFactory: DatabaseHandleFactory

    private init(databaseHandleFactory: @escaping DatabaseHandleFactory) {
        self.databaseHandleFactory = databaseHandleFactory
        protectedDatabaseHandle = OSAllocatedUnfairLock(initialState: nil)
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

        for version in AppDatabaseVersion.allCases {
            migrator.registerMigration(version.id) { database in
                for tableKind in AppDatabaseTableKind.allCases {
                    try tableKind.table.registerForVersion(version, in: database)
                }
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
