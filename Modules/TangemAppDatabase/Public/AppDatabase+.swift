//
//  AppDatabase+.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

// MARK: - Convenience extensions

public extension AppDatabase {
    static func makeWithQueue() -> AppDatabase {
        return AppDatabase { databaseFilePath in
            return try DatabaseQueue(path: databaseFilePath)
        }
    }

    static func makeWithPool() -> AppDatabase {
        return AppDatabase { databaseFilePath in
            return try DatabasePool(path: databaseFilePath)
        }
    }

    static func makeWithInMemoryStorage() -> AppDatabase {
        return AppDatabase { _ in
            return try DatabaseQueue()
        }
    }
}
