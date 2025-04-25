//
//  Fact0rnWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Fact0rnWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .fact0rn(address: input.wallet.defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(
            network: Fact0rnMainNetworkParams(),
            unspentOutputManager: unspentOutputManager
        )

        let providers: [UTXONetworkProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, _ in
                let electrumWebSocketProvider = ElectrumWebSocketProvider(url: nodeInfo.url)
                let provider = Fact0rnNetworkProvider(provider: electrumWebSocketProvider)

                return provider
            })

        let networkService = MultiUTXONetworkProvider(providers: providers)
        return Fact0rnWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
