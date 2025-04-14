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
import TangemNetworkUtils

struct RavencoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let bitcoinManager = BitcoinManager(
            networkParams: input.wallet.blockchain.isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams(),
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressedKey,
            bip: .bip44
        )
        let unspentOutputManager: UnspentOutputManager = .ravencoin(address: input.wallet.defaultAddress, isTestnet: input.wallet.blockchain.isTestnet)

        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        let providers: [UTXONetworkProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, providerType in
                switch providerType {
                case .nowNodes:
                    networkProviderAssembly.makeBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .nowNodes
                    )
                default:
                    RavencoinNetworkProvider(
                        host: nodeInfo.link,
                        provider: .init(configuration: input.networkInput.tangemProviderConfig)
                    )
                }
            }

        let networkService = MultiUTXONetworkProvider(providers: providers)
        return RavencoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
