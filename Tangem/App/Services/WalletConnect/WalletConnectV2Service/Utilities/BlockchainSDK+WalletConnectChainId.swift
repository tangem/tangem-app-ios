//
//  BlockchainSDK+WalletConnectChainId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension BlockchainSdk.Blockchain {
    /// WalletConnect has own chainid, which not always similar with us networkid and not all DApps use blockchain IDs from wc docs : |
    ///  Full chain ids list: https://docs.reown.com/cloud/chains/chain-list
    var wcChainID: [String]? {
        switch self {
        case .solana:
            let mainnetIds = ["5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ"]
            let testnetIds = ["4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z"]

            return isTestnet ? testnetIds : mainnetIds
        default:
            guard let chainId, isEvm else { return nil }

            return [String(chainId)]
        }
    }
}
