//
//  BittensorWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BittensorWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let network = PolkadotNetwork(blockchain: input.wallet.blockchain),
              case .bittensor = network else {
            throw BlockchainSdkError.empty
        }

        return PolkadotWalletManager(network: network, wallet: input.wallet).then {
            let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

            let blockchain = input.wallet.blockchain

            var providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
                .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                    PolkadotJsonRpcProvider(node: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
                }

            let dwellirResolver = DwellirAPIResolver(keysConfig: input.networkInput.keysConfig)

            if let dwellirNodeInfo = dwellirResolver.resolve(for: blockchain) {
                providers.append(PolkadotJsonRpcProvider(node: dwellirNodeInfo, configuration: input.networkInput.tangemProviderConfig))
            }

            let onfinalityResolver = OnfinalityAPIResolver(keysConfig: input.networkInput.keysConfig)

            if let onfinalityNodeInfo = onfinalityResolver.resolve() {
                providers.append(PolkadotJsonRpcProvider(node: onfinalityNodeInfo, configuration: input.networkInput.tangemProviderConfig))
            }

            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(
                blockchain: input.wallet.blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network,
                runtimeVersionProvider: runtimeVersionProvider
            )
        }
    }
}
