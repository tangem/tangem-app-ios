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

        let providers: [AlephiumNetworkProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                AlephiumNetworkProvider(
                    node: nodeInfo,
                    networkConfig: input.networkInput.tangemProviderConfig
                )
            }

        return AlephiumWalletManager(
            wallet: input.wallet,
            networkService: AlephiumNetworkService(providers: providers),
            transactionBuilder: AlephiumTransactionBuilder(
                isTestnet: input.wallet.blockchain.isTestnet,
                walletPublicKey: compressedKey,
                decimalValue: input.wallet.blockchain.decimalValue
            )
        )
    }
}
