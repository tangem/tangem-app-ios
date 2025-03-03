//
//  DashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DashWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let bitcoinManager = BitcoinManager(
            networkParams: input.blockchain.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressed,
            bip: .bip44
        )

        let unspentOutputManager = CommonUnspentOutputManager()
        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        let providers: [UTXONetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input,
                        for: .nowNodes
                    )
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .dash,
                        with: input
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .dash,
                        with: input
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input,
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
