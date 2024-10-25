//
//  KoinosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct KoinosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let isTestnet = blockchain.isTestnet
        let koinosNetworkParams = KoinosNetworkParams(isTestnet: isTestnet)

        return KoinosWalletManager(
            wallet: input.wallet,
            networkService: KoinosNetworkService(
                providers: APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                    .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                        KoinosNetworkProvider(
                            node: nodeInfo,
                            koinosNetworkParams: koinosNetworkParams,
                            configuration: input.networkConfig
                        )
                    }
            ),
            transactionBuilder: KoinosTransactionBuilder(koinosNetworkParams: koinosNetworkParams)
        )
    }
}
