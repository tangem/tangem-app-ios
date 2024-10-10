//
//  HederaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let wallet = input.wallet
        let blockchain = input.blockchain
        let isTestnet = blockchain.isTestnet
        let networkConfig = input.networkConfig
        let dependencies = input.blockchainSdkDependencies

        let restProviders = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                HederaRESTNetworkProvider(targetConfiguration: nodeInfo, providerConfiguration: networkConfig)
            }

        let consensusProvider = HederaConsensusNetworkProvider(isTestnet: isTestnet)

        let networkService = HederaNetworkService(
            consensusProvider: consensusProvider,
            restProviders: restProviders
        )

        let transactionBuilder = HederaTransactionBuilder(
            publicKey: wallet.publicKey.blockchainKey,
            curve: blockchain.curve,
            isTestnet: isTestnet
        )

        return HederaWalletManager(
            wallet: wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder,
            accountCreator: dependencies.accountCreator,
            dataStorage: dependencies.dataStorage
        )
    }
}
