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
        case .ethereum:
            let chainIds: [String] = SupportedBlockchains.all.compactMap {
                guard let chainId = $0.chainId else { return nil }
                return String(chainId)
            }

            return chainIds
        case .solana:
            let mainnetIds = ["5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ"]
            let testnetIds = ["4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z"]

            return isTestnet ? testnetIds : mainnetIds
        default:
            return nil
        }
    }
}
