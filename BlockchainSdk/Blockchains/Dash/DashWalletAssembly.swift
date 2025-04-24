//
//  DashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DashWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .dash(
            address: input.wallet.defaultAddress,
            isTestnet: input.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            network: input.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
            unspentOutputManager: unspentOutputManager
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
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .dash,
                        with: input.networkInput
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .dash,
                        with: input.networkInput
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .getBlock
                    )
                )
            default:
                return
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
