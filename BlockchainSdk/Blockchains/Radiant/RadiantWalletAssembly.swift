//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })
        let providers: [RadiantNetworkProvider] = socketManagers.map {
            RadiantNetworkProvider(provider: $0, isTestnet: input.blockchain.isTestnet)
        }
        let publicKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let unspentOutputManager = CommonUnspentOutputManager()
        let transactionBuilder = try RadiantTransactionBuilder(
            walletPublicKey: publicKey,
            unspentOutputManager: unspentOutputManager,
            decimalValue: input.blockchain.decimalValue
        )

        return RadiantWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            unspentOutputManager: unspentOutputManager,
            networkService: MultiUTXONetworkProvider(providers: providers)
        )
    }
}
