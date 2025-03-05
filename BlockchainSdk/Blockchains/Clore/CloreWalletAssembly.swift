//
//  CloreWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct CloreWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let bitcoinManager = BitcoinManager(
            networkParams: CloreMainNetworkParams(),
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressedKey,
            bip: .bip44
        )

        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            addresses: input.wallet.addresses
        )

        let providers: [AnyBitcoinNetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .clore(nodeInfo.url)).eraseToAnyBitcoinNetworkProvider()
            }

        let networkService = BitcoinNetworkService(providers: providers)
        return RavencoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, networkService: networkService)
    }
}
