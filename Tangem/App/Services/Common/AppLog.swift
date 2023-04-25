//
//  AppLog.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemSwapping

class AppLog {
    static let shared = AppLog()

    private let consoleLogger = ConsoleLogger()
    private let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        .custom(
            logLevel: Log.Level.allCases,
            loggers: [fileLogger, consoleLogger]
        )
    }

    func configure() {
        Log.config = sdkLogConfig
        fileLogger.removeLogFileIfNeeded()
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        Log.debug(message())
    }

    func error(_ error: Error) {
        self.error(error: error, params: [:])
    }

    func logAppLaunch(_ currentLaunch: Int) {
        consoleLogger.log("Current launch number: \(currentLaunch)", level: .debug)
        fileLogger.logAppLaunch(currentLaunch)
    }
}

extension AppLog: SwappingLogger {}
