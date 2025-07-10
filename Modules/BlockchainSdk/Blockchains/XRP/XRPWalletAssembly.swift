//
//  XRPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XRPWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try XRPWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.wallet.blockchain.curve)

            let blockchain = input.wallet.blockchain
            let config = input.networkInput.keysConfig
            let providers: [XRPNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: config)
                .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                    XRPNetworkProvider(node: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
                }

            $0.networkService = XRPNetworkService(providers: providers)
        }
    }
}
