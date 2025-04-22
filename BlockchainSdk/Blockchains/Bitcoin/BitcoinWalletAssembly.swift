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
            address: input.wallet.defaultAddress,
            isTestnet: input.wallet.blockchain.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            network: input.wallet.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinNetworkParams(),
            unspentOutputManager: unspentOutputManager
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
            default:
                break
            }
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
