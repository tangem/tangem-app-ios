//
//  JointAccountSupportedBlockchains.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum JointAccountSupportedBlockchains {
    static let all: [Blockchain] = [
        .ethereum(testnet: false),
        .avalanche(testnet: false),
        .arbitrum(testnet: false),
        .optimism(testnet: false),
        .base(testnet: false),
        .bsc(testnet: false),
        .polygon(testnet: false),
    ]
}
