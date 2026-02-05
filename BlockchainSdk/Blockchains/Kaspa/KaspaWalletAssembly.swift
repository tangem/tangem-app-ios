//
//  KaspaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct KaspaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain

        let providers = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                KaspaNetworkProvider(
                    url: nodeInfo.url,
                    isTestnet: blockchain.isTestnet,
                    networkConfiguration: input.networkInput.tangemProviderConfig
                )
            }

        let providerKRC20URL = blockchain.isTestnet
            ? URL(string: "https://tn10api.kasplex.org/v1")!
            : URL(string: "https://api.kasplex.org/v1/")!

        let providersKRC20 = [
            KaspaNetworkProviderKRC20(
                url: providerKRC20URL,
                networkConfiguration: input.networkInput.tangemProviderConfig
            ),
        ]

        let unspentOutputManager: UnspentOutputManager = .kaspa(address: input.wallet.defaultAddress)
        let txBuilder = KaspaTransactionBuilder(
            walletPublicKey: input.wallet.publicKey,
            unspentOutputManager: unspentOutputManager,
            isTestnet: blockchain.isTestnet
        )

        return KaspaWalletManager(
            wallet: input.wallet,
            networkService: KaspaNetworkService(providers: providers),
            networkServiceKRC20: KaspaNetworkServiceKRC20(providers: providersKRC20),
            txBuilder: txBuilder,
            unspentOutputManager: unspentOutputManager,
            dataStorage: input.blockchainSdkDependencies.dataStorage
        )
    }
}
