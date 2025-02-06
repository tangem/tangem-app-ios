//
//  AppLog.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import protocol TangemExpress.Logger
import protocol TangemVisa.VisaLogger
import protocol TangemStaking.Logger

class AppLog {
    static let shared = AppLog()

    let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        var loggers: [TangemSdkLogger] = [ /* fileLogger */ ]

        if AppEnvironment.current.isDebug {
            loggers.append(ConsoleLogger())
        }

        return .custom(
            logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
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

    // [REDACTED_TODO_COMMENT]
    func debugDetailed<T>(file: StaticString = #fileID, line: UInt = #line, _ message: @autoclosure () -> T) {
        Log.debug("\(file):\(line): \(message())")
    }

    func error(_ error: Error) {
        self.error(error: error, params: [:])
    }

    func logAppLaunch(_ currentLaunch: Int) {
        let dashSeparator = String(repeating: "-", count: 25)
        let sessionMessage = "\(dashSeparator) New session. Session id: \(AppConstants.sessionId) \(dashSeparator)"
        let launchNumberMessage = "\(dashSeparator) Current launch number: \(currentLaunch) \(dashSeparator)"
        let deviceInfoMessage = "\(dashSeparator) \(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", ")) \(dashSeparator)"
        debug("\n\(sessionMessage)\n\(launchNumberMessage)\n\(deviceInfoMessage)\n\n")
    }
}

extension AppLog: TangemExpress.Logger {}

extension AppLog: VisaLogger {}

extension AppLog: TangemStaking.Logger {}
