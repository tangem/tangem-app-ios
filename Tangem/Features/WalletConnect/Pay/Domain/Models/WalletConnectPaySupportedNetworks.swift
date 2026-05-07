//
//  WalletConnectPaySupportedNetworks.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum WalletConnectPaySupportedNetworks {
    static let evmBlockchains: [Blockchain] = [
        .ethereum(testnet: false),
        .base(testnet: false),
        .polygon(testnet: false),
        .optimism(testnet: false),
        .arbitrum(testnet: false),
    ]
}
