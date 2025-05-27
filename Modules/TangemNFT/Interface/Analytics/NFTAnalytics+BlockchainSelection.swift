//
//  BlockchainSelection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct BlockchainSelection {
        let logBlockchainChosen: LogWithBlockchainClosure

        public init(
            logBlockchainChosen: @escaping LogWithBlockchainClosure,
        ) {
            self.logBlockchainChosen = logBlockchainChosen
        }
    }
}
