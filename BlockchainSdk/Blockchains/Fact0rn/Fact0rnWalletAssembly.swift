//
//  Fact0rnWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct Fact0rnWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let bitcoinManager = BitcoinManager(
            networkParams: Fact0rnMainNetworkParams(),
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressedKey,
            bip: .bip84
        )

        let unspentOutputManager = CommonUnspentOutputManager()
        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        let providers: [UTXONetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                let electrumWebSocketProvider = ElectrumWebSocketProvider(url: nodeInfo.url)
                let provider = Fact0rnNetworkProvider(provider: electrumWebSocketProvider)

                return provider
            })

        let networkService = MultiUTXONetworkProvider(providers: providers)
        return Fact0rnWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
