//
//  RavencoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct RavencoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let bitcoinManager = BitcoinManager(
            networkParams: input.blockchain.isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams(),
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressedKey,
            bip: .bip44
        )

        let unspentOutputManager = CommonUnspentOutputManager()
        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        let blockchain = input.blockchain
        let providers: [AnyBitcoinNetworkProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, providerType in
                switch providerType {
                case .nowNodes:
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input,
                        for: .nowNodes
                    ).eraseToAnyBitcoinNetworkProvider()
                default:
                    RavencoinNetworkProvider(
                        host: nodeInfo.link,
                        provider: .init(configuration: input.networkConfig)
                    )
                    .eraseToAnyBitcoinNetworkProvider()
                }
            }

        let networkService = BitcoinNetworkService(providers: providers)
        return RavencoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
