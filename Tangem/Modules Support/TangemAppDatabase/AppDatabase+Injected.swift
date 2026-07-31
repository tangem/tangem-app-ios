//
//  AppDatabase+Injected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAppDatabase

extension InjectedValues {
    var appDatabase: AppDatabase {
        get { Self[AppDatabaseKey.self] }
        set { Self[AppDatabaseKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct AppDatabaseKey: InjectionKey {
    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]
    static var currentValue = AppDatabase.makeWithQueue()
}
