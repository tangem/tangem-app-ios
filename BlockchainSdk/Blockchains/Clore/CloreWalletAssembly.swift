//
//  CloreWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CloreWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .clore(address: input.wallet.defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(
            network: CloreMainNetworkParams(),
            unspentOutputManager: unspentOutputManager
        )

        let providers: [UTXONetworkProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .clore(nodeInfo.url))
            }

        let networkService = MultiUTXONetworkProvider(providers: providers)
        return BitcoinWalletManager(
            wallet: input.wallet,
            txBuilder: txBuilder,
            unspentOutputManager: unspentOutputManager,
            networkService: networkService
        )
    }
}
