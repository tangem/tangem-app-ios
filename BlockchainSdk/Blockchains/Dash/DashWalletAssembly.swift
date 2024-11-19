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
        try BitcoinWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )

            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)

            let providers: [AnyBitcoinNetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
                switch providerType {
                case .nowNodes:
                    partialResult.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider())
                case .blockchair:
                    partialResult.append(contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .dash, with: input))
                case .blockcypher:
                    partialResult.append(networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .dash, with: input).eraseToAnyBitcoinNetworkProvider())
                default:
                    return
                }
            }

            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
}
