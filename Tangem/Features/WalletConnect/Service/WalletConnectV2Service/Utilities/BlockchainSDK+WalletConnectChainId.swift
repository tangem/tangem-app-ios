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
        case .bitcoin:
            // Bitcoin chain id according to Reown docs from link above.
            let mainnetIds = ["000000000019d6689c085ae165831e93"]
            let testnetIds = ["000000000933ea01ad0ee984209779ba"]
            return isTestnet ? testnetIds : mainnetIds
        case .tron:
            // CAIP-2 references are the first 4 bytes of the genesis block id. Nile is the testnet the SDK talks to,
            // Shasta is accepted for dApps that only know that one.
            let mainnetIds = ["0x2b6653dc"]
            let testnetIds = ["0xcd8690dc", "0x94a9059e"]
            return isTestnet ? testnetIds : mainnetIds
        default:
            guard let chainId, isEvm else { return nil }

            return [String(chainId)]
        }
    }
}
