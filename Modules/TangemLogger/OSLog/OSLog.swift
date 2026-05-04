//
//  OSLog.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import OSLog

typealias OSLog = os.Logger

extension OSLog {
    typealias Category = OSLogCategory
    typealias Level = OSLogLevel
}

extension OSLog {
    func log(level: Level, message: String) {
        switch level {
        case .debug: debug("\(message, privacy: .private)")
        case .info: info("\(message, privacy: .private)")
        case .warning: error("\(message, privacy: .private)")
        case .error: fault("\(message, privacy: .private)")
        }
    }
}

extension OSLog {
    /// Returns the pre-built `os.Logger` stored on the category.
    static func logger(for category: Category) -> OSLog {
        category.osLogger
    }
}
