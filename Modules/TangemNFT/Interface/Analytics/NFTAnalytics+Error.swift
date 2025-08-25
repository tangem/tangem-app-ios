//
//  Error.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct Error {
        // MARK: Aliases

        public typealias LogErrorClosure = (ErrorCode, ErrorDescription) -> Void
        public typealias ErrorCode = String
        public typealias ErrorDescription = String

        // MARK: Action

        public let logError: LogErrorClosure

        // MARK: Init

        public init(logError: @escaping LogErrorClosure) {
            self.logError = logError
        }
    }
}
