//
//  TronWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TronWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return TronWalletManager(wallet: input.wallet).then {
            let blockchain = input.wallet.blockchain

            let providers: [TronJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
                .resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, _ in
                    TronJsonRpcProvider(node: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
                })

            $0.networkService = TronNetworkService(isTestnet: blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder()
        }
    }
}
