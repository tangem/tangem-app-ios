//
//  DogecoinAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DogecoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .dogecoin(address: input.wallet.defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(
            network: DogecoinNetworkParams(),
            unspentOutputManager: unspentOutputManager,
            builderType: .walletCore(.dogecoin)
        )

        let providers: [UTXONetworkProvider] = input.networkInput.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .nowNodes
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .getBlock
                    )
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .dogecoin,
                        with: input.networkInput
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .dogecoin,
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
                return
            }
        }

        let networkService = MultiUTXONetworkProvider(
            providers: providers,
            blockchainName: Blockchain.dogecoin.displayName
        )

        return DogecoinWalletManager(
            wallet: input.wallet,
            txBuilder: txBuilder,
            unspentOutputManager: unspentOutputManager,
            networkService: networkService
        )
    }
}
