//
//  VeChainWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain
        let providers: [VeChainNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                VeChainNetworkProvider(nodeInfo: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
            }

        let networkService = VeChainNetworkService(
            blockchain: blockchain,
            providers: providers
        )

        let transactionBuilder = VeChainTransactionBuilder(isTestnet: blockchain.isTestnet)

        return VeChainWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
