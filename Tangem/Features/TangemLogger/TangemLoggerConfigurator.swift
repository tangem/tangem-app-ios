//
//  TangemLoggerConfigurator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLogger
import TangemFoundation
import class TangemSdk.Log
import protocol TangemSdk.TangemSdkLogger

public let TSDKLogger = Logger(category: OSLogCategory(name: "TangemSDK", prefix: .none))

struct TangemLoggerConfigurator: Initializable {
    let tangemSDKLogConfig: Log.Config = .custom(
        logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
        loggers: [TangemSDKLogger()]
    )

    func initialize() {
        LegacyFileLogger().remove()
        TangemLogger.Logger.configuration = TangemLoggerConfiguration()
        // TangemSDK logger
        Log.config = tangemSDKLogConfig
    }
}

// MARK: - TangemLogger.Configuration

struct TangemLoggerConfiguration: TangemLogger.Logger.Configuration {
    /// Write to console
    func isLoggable() -> Bool {
        AppEnvironment.current.isDebug
    }

    /// Write to file
    func isWritable() -> Bool {
        true
    }
}

// MARK: - TangemSDKLogger

struct TangemSDKLogger: TangemSdkLogger {
    func log(_ message: String, level: Log.Level) {
        let prefix = level.prefix.isEmpty ? level.emoji : "\(level.emoji)\(level.prefix)"

        switch level {
        case .error:
            TSDKLogger.error(error: "\(prefix) \(message)")
        case .warning:
            TSDKLogger.warning("\(prefix) \(message)")
        default:
            TSDKLogger.debug("\(prefix) \(message)")
        }
    }
}
