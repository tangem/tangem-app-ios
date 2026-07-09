//
//  CommonTransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

final class CommonTransactionHistoryAuxDataStorage {
    typealias DatabaseHandle = DatabaseReader & DatabaseWriter
    typealias DatabaseHandleFactory = (_ databaseFilePath: String) throws -> DatabaseHandle

    private let databaseHandleFactory: DatabaseHandleFactory

    init(databaseHandleFactory: @escaping DatabaseHandleFactory) {
        self.databaseHandleFactory = databaseHandleFactory
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        try! configureDatabase()
    }

    // MARK: - Factory methods

    private func configureDatabase() throws {
        let databasePath = try Self.makeDatabaseFilePath()
        let migrator = Self.makeDatabaseMigrator()
        let databaseHandle = try databaseHandleFactory(databasePath)

        try migrator.migrate(databaseHandle)
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
        }

        return migrator
    }
}

// MARK: - Constants

private extension CommonTransactionHistoryAuxDataStorage {
    enum Constants {
        static let databaseDirectoryName = "TransactionHistoryAuxData"
        static let databaseFileName = "db.sqlite"
    }
}
