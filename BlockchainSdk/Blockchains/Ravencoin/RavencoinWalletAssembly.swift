//
//  RavencoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .ravencoin(address: input.wallet.defaultAddress, isTestnet: input.wallet.blockchain.isTestnet)

        let txBuilder = BitcoinTransactionBuilder(
            network: input.wallet.blockchain.isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams(),
            unspentOutputManager: unspentOutputManager,
            builderType: .walletCore(.ravencoin)
        )

        let providers: [UTXONetworkProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, providerType in
                switch providerType {
                case .nowNodes:
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .nowNodes
                    )
                default:
                    RavencoinNetworkProvider(
                        nodeInfo: nodeInfo,
                        provider: .init(configuration: input.networkInput.tangemProviderConfig)
                    )
                }
            }

        let networkService = MultiUTXONetworkProvider(
            providers: providers,
            blockchainName: Blockchain.ravencoin(testnet: false).displayName
        )

        return BitcoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
