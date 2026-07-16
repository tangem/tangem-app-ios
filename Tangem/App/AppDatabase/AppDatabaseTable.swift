//
//  AppDatabaseTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

/// An interface representing a database table, which can be registered in the database.
protocol AppDatabaseTable: Sendable {
    static var tableName: String { get }

    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws
}
