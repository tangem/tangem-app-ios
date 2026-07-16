//
//  AppDatabase+Injected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

extension InjectedValues {
    var appDatabase: AppDatabase {
        get { Self[AppDatabaseKey.self] }
        set { Self[AppDatabaseKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct AppDatabaseKey: InjectionKey {
    static var currentValue = AppDatabase { databaseFilePath in
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        return try DatabaseQueue(path: databaseFilePath)
    }
}
