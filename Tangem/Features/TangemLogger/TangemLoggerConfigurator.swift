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
    func shouldLogMessage(with logLevel: TangemLogger.Logger.Level) -> Bool {
        switch logLevel {
        case .debug,
             .info,
             .warning,
             .error:
            return AppEnvironment.current.isDebug
        }
    }

    func shouldWriteMessage(with logLevel: TangemLogger.Logger.Level) -> Bool {
        switch logLevel {
        case .info,
             .warning,
             .error:
            return true
        case .debug:
            // Persist debug too, so the exported archive carries every severity.
            return !AppEnvironment.current.isProduction
        }
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
        case .command,
             .tlv,
             .session,
             .nfc,
             .network,
             .view:
            TSDKLogger.info("\(prefix) \(message)")
        case .apdu,
             .debug:
            TSDKLogger.debug("\(prefix) \(message)")
        }
    }
}
