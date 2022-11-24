//
//  Logger.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]

enum Logger {
    static func debug(_ args: Any...) {
        #if DEBUG
        log(.debug, args)
        #endif
    }

    static func info(_ args: Any...) {
        log(.info, args)
    }

    static func warning(_ args: Any...) {
        log(.warning, args)
    }

    static func error(_ args: Any...) {
        log(.error, args)
    }

    private static func log(_ type: LogType, _ args: Any...) {
        print(type.prefix, args)
    }
}

private enum LogType {
    case debug
    case info
    case warning
    case error

    var prefix: String {
        switch self {
        case .debug:
            return "🐞"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "‼️"
        }
    }
}
