//
//  NEARWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let networkConfig = input.networkConfig

        let providers: [NEARNetworkProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                return NEARNetworkProvider(baseURL: nodeInfo.url, configuration: networkConfig)
            }

        let networkService = NEARNetworkService(blockchain: blockchain, providers: providers)
        let transactionBuilder = NEARTransactionBuilder()

        return NEARWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder,
            protocolConfigCache: .shared
        )
    }
}
