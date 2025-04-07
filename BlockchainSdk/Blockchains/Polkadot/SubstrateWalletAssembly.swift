//
//  KusumaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SubstrateWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain

        guard let network = PolkadotNetwork(blockchain: blockchain) else {
            throw WalletError.empty
        }

        return PolkadotWalletManager(network: network, wallet: input.wallet).then { walletManager in
            let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)
            let providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
                .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                    PolkadotJsonRpcProvider(node: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
                }

            walletManager.networkService = PolkadotNetworkService(providers: providers, network: network)
            walletManager.txBuilder = PolkadotTransactionBuilder(
                blockchain: blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network,
                runtimeVersionProvider: runtimeVersionProvider
            )
        }
    }
}
