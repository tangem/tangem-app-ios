//
//  BitcoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .bitcoin(
            isTestnet: input.wallet.blockchain.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            network: input.wallet.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinNetworkParams(),
            unspentOutputManager: unspentOutputManager,
            builderType: .walletCore(.bitcoin)
        )

        let providers: [UTXONetworkProvider] = input.networkInput.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .nowNodes)
                )
            case .getBlock where !input.wallet.blockchain.isTestnet:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .getBlock)
                )
            case .public(let link):
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .public(link))
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .bitcoin(testnet: input.wallet.blockchain.isTestnet),
                        with: input.networkInput
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .bitcoin(testnet: input.wallet.blockchain.isTestnet),
                        with: input.networkInput
                    )
                )
            case .mock:
                if let node = APINodeInfoResolver(
                    blockchain: input.networkInput.blockchain,
                    keysConfig: input.networkInput.keysConfig
                ).resolve(for: .mock) {
                    let provider = BlockBookUTXOProvider(
                        blockchain: input.networkInput.blockchain,
                        blockBookConfig: MockBlockBookConfig(urlNode: node.url),
                        networkConfiguration: input.networkInput.tangemProviderConfig
                    )
                    partialResult.append(provider)
                }
            default:
                break
            }
        }

        let networkService = BitcoinNetworkService(
            providers: providers,
            blockchainName: input.wallet.blockchain.displayName,
        )

        return BitcoinWalletManager(
            wallet: input.wallet,
            txBuilder: txBuilder,
            unspentOutputManager: unspentOutputManager,
            networkService: networkService
        )
    }
}
