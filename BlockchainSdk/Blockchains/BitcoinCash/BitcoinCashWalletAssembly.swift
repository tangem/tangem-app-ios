//
//  BitcoinCashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinCashWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let networkParams: UTXONetworkParams = input.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()

        let unspentOutputManager: UnspentOutputManager = .bitcoinCash(
            address: input.wallet.defaultAddress,
            isTestnet: input.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            network: networkParams,
            unspentOutputManager: unspentOutputManager
        )

        // [REDACTED_TODO_COMMENT]
        // Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
        let providers: [UTXONetworkProvider] = input.networkInput.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .nowNodes,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .getBlock,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .bitcoinCash,
                        with: input.networkInput
                    )
                )
            default:
                return
            }
        }

        let networkService = BitcoinCashNetworkService(providers: providers)
        return BitcoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
