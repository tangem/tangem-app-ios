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
    private static let queue = DispatchQueue(label: subsystem)
    private static let subsystem = "com.tangem.os.logger"
    private static var loggers: [Category: OSLog] = [:]

    static func logger(for category: Category) -> OSLog {
        queue.sync {
            if let logger = loggers[category] {
                return logger
            }

            let logger = OSLog(subsystem: subsystem, category: category.name.capitalized)
            loggers[category] = logger
            return logger
        }
    }
}
