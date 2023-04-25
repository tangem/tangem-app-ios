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

    private let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        var loggers: [TangemSdkLogger] = [fileLogger]

        if AppEnvironment.current.isDebug {
            loggers.append(ConsoleLogger())
        }

        return .custom(
            logLevel: Log.Level.allCases,
            loggers: loggers
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
        debug("Current launch number: \(currentLaunch)")
        fileLogger.logAppLaunch(currentLaunch)
    }
}

extension AppLog: SwappingLogger {}
