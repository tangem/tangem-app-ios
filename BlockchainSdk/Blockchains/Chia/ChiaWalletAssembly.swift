//
//  ChiaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let resolver = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
        let providers: [ChiaNetworkProvider] = resolver.resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, _ in
            ChiaNetworkProvider(node: nodeInfo, networkConfig: input.networkInput.tangemProviderConfig)
        })

        return try ChiaWalletManager(
            wallet: input.wallet,
            networkService: .init(
                providers: providers,
                blockchain: input.wallet.blockchain
            ),
            txBuilder: .init(
                isTestnet: input.wallet.blockchain.isTestnet,
                walletPublicKey: input.wallet.publicKey.blockchainKey
            )
        )
    }
}
