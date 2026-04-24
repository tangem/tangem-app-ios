//
//  AlgorandWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlgorandWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        var providers: [AlgorandNetworkProvider] = []

        let blockchain = input.wallet.blockchain

        let apiResolver = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
        providers = apiResolver.resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, apiInfo in
            AlgorandNetworkProvider(
                node: nodeInfo,
                networkConfig: input.networkInput.tangemProviderConfig
            )
        })

        let transactionBuilder = AlgorandTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            curve: input.wallet.blockchain.curve,
            isTestnet: input.wallet.blockchain.isTestnet
        )

        return try AlgorandWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: .init(blockchain: input.wallet.blockchain, providers: providers)
        )
    }
}
