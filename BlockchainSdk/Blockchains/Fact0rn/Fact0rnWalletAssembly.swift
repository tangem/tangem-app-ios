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
        try Fact0rnWalletManager(wallet: input.wallet).then {
            let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: Fact0rnMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressedKey,
                bip: .bip84
            )

            $0.txBuilder = BitcoinTransactionBuilder(
                bitcoinManager: bitcoinManager,
                addresses: input.wallet.addresses
            )

            let providers: [AnyBitcoinNetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                    let electrumWebSocketProvider = ElectrumWebSocketProvider(url: nodeInfo.url)
                    let provider = Fact0rnNetworkProvider(
                        provider: electrumWebSocketProvider,
                        decimalValue: input.blockchain.decimalValue
                    )

                    return AnyBitcoinNetworkProvider(provider)
                })

            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
}
