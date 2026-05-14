//
//  Logger+Configuration.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Configuration

public extension Logger {
    protocol Configuration {
        /// Write to console.
        func shouldLogMessage(with logLevel: Logger.Level) -> Bool

        /// Write to log file.
        func shouldWriteMessage(with logLevel: Logger.Level) -> Bool
    }

    struct DefaultConfiguration: Configuration {
        public init() {}

        public func shouldLogMessage(with logLevel: Logger.Level) -> Bool { false }
        public func shouldWriteMessage(with logLevel: Logger.Level) -> Bool { false }
    }
}

// MARK: - PrefixBuilder

public extension Logger {
    protocol Tagable {
        func tag(_ tag: String) -> Self
    }
}
