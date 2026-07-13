//
//  AppDatabaseTable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

protocol AppDatabaseTable: Sendable {
    static func registerForVersion(_ version: AppDatabaseVersion, in database: Database) throws
}
