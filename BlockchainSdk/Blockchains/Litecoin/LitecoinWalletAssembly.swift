//
//  LitecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct LitecoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let unspentOutputManager: UnspentOutputManager = .litecoin(address: input.wallet.defaultAddress)
        let txBuilder = BitcoinTransactionBuilder(
            network: LitecoinNetworkParams(),
            unspentOutputManager: unspentOutputManager
        )
        let providers: [UTXONetworkProvider] = input.networkInput.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .nowNodes)
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input.networkInput, for: .getBlock)
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .litecoin, with: input.networkInput)
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .litecoin, with: input.networkInput)
                )
            default:
                return
            }
        }

        let networkService = LitecoinNetworkService(providers: providers)
        return BitcoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
