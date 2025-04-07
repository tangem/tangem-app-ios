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
        let blockchain = input.wallet.blockchain

        let providers: [NEARNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                return NEARNetworkProvider(baseURL: nodeInfo.url, configuration: input.networkInput.tangemProviderConfig)
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
