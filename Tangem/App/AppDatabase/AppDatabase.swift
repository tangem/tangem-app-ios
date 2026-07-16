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

final class AppDatabase {
    /// - Note: Inherits `DatabaseReader` too.
    typealias DatabaseHandle = DatabaseWriter

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

    @available(iOS, deprecated: 100000.0, message: "For unit tests only, use `AppDatabase.shared` instead")
    init(databaseHandleFactory: @escaping DatabaseHandleFactory) {
        self.databaseHandleFactory = databaseHandleFactory
        protectedDatabaseHandle = OSAllocatedUnfairLock(initialState: nil)
    }

    // MARK: - Helpers

    /// Call early to prepare & warm up the database and avoid heavy IO work on the first database access.
    func prepare() {
        DispatchQueue.global(qos: .utility).async {
            do {
                _ = try self.databaseHandle
            } catch {
                AppLogger.error("Failed to prepare & warm up database", error: error)
            }
        }
    }

    // MARK: - File system helpers

    /// The database directory is deliberately *included* in backups: this storage is planned
    /// to hold user data in the future, not just throw-away caches.
    private static func applyURLResourceValues(to url: inout URL) {
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = false
            try url.setResourceValues(values)
        } catch {
            AppLogger.error("Failed to apply URL resource values for app DB at URL \(url)", error: error)
        }
    }

    /// The database files are deliberately protected as *complete unless open*: the database can only
    /// be opened while the device is unlocked, but once open it stays readable and writable after
    /// the device locks, so in-flight background work can finish.
    private static func applyFileAttributes(to filePaths: [String]) {
        let fileManager = FileManager.default
        let fileProtectionType: FileProtectionType = .completeUnlessOpen

        for path in filePaths where fileManager.fileExists(atPath: path) {
            do {
                try fileManager.setAttributes([.protectionKey: fileProtectionType], ofItemAtPath: path)
            } catch {
                AppLogger.error("Failed to set file protection attributes for app DB at path \(path)", error: error)
            }
        }
    }

    // MARK: - Factory methods

    private static func makeDatabaseHandle(using databaseHandleFactory: DatabaseHandleFactory) throws -> DatabaseHandle {
        let databaseFilePath = try makeDatabaseFilePath()
        let migrator = makeDatabaseMigrator()
        let databaseHandle = try databaseHandleFactory(databaseFilePath)
        let databaseAuxFilePaths = [
            Constants.databaseWALSuffix,
            Constants.databaseSHMSuffix,
            Constants.databaseJournalSuffix,
        ].map { databaseFilePath + $0 }

        applyFileAttributes(to: databaseAuxFilePaths + [databaseFilePath])

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

        var databaseDirectoryURL = applicationSupportDirectoryURL.appendingPathComponent(
            Constants.databaseDirectoryName,
            isDirectory: true
        )

        try fileManager.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: true)
        applyURLResourceValues(to: &databaseDirectoryURL)

        return databaseDirectoryURL
            .appending(path: Constants.databaseFileName, directoryHint: .notDirectory)
            .path
    }

    private static func makeDatabaseMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // For app development only, see
        // https://swiftpackageindex.com/groue/grdb.swift/master/documentation/grdb/databasemigrator/erasedatabaseonschemachange
        // for details
        migrator.eraseDatabaseOnSchemaChange = true
        #endif // DEBUG

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
        static let databaseWALSuffix = "-wal"
        static let databaseSHMSuffix = "-shm"
        static let databaseJournalSuffix = "-journal"
    }
}
