//
//  Collections.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct Collections {
        public typealias Standard = String
        public typealias LogDetailsOpenedClosure = (Blockchain, Standard) -> Void

        let logReceiveOpen: () -> Void
        let logDetailsOpen: LogDetailsOpenedClosure

        public init(logReceiveOpen: @escaping () -> Void, logDetailsOpen: @escaping LogDetailsOpenedClosure) {
            self.logReceiveOpen = logReceiveOpen
            self.logDetailsOpen = logDetailsOpen
        }
    }
}
