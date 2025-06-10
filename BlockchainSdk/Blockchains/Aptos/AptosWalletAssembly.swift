//
//  AptosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let chainId: AptosChainId = input.wallet.blockchain.isTestnet ? .testnet : .mainnet

        let blockchain = input.wallet.blockchain
        let apiResolver = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
        let providers: [AptosNetworkProvider] = apiResolver.resolveProviders(
            apiInfos: input.networkInput.apiInfo,
            factory: { nodeInfo, _ in
                AptosNetworkProvider(node: nodeInfo, networkConfig: input.networkInput.tangemProviderConfig)
            }
        )

        let txBuilder = AptosTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            decimalValue: input.wallet.blockchain.decimalValue,
            walletAddress: input.wallet.address,
            chainId: chainId
        )

        let networkService = AptosNetworkService(providers: providers)

        return AptosWalletManager(wallet: input.wallet, transactionBuilder: txBuilder, networkService: networkService)
    }
}
