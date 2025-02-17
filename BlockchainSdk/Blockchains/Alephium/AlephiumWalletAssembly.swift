//
//  AlephiumWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlephiumWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let providers: [AlephiumNetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                AlephiumNetworkProvider(
                    node: nodeInfo,
                    networkConfig: input.networkConfig
                )
            }

        return AlephiumWalletManager(
            wallet: input.wallet,
            networkService: AlephiumNetworkService(providers: providers),
            transactionBuilder: AlephiumTransactionBuilder(
                isTestnet: input.blockchain.isTestnet,
                walletPublicKey: compressedKey,
                decimalValue: input.blockchain.decimalValue
            )
        )
    }
}
