//
//  AppLog.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AppLog {
    static var sdkLogConfig: Log.Config {
        .custom(logLevel: Log.Level.allCases,
                loggers: [FileLogger(), ConsoleLogger()])
    }

    static func configure() {
        Log.config = sdkLogConfig
    }

    static func debug<T>(_ message: @autoclosure () -> T) {
        Log.debug(message())
    }
}
