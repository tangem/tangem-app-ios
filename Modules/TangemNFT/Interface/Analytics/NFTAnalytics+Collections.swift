//
//  Collections.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct Collections {
        let logReceiveOpen: () -> Void
        let logDetailsOpen: LogWithBlockchainClosure

        public init(logReceiveOpen: @escaping () -> Void, logDetailsOpen: @escaping LogWithBlockchainClosure) {
            self.logReceiveOpen = logReceiveOpen
            self.logDetailsOpen = logDetailsOpen
        }
    }
}
