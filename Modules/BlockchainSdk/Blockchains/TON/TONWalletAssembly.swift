//
//  TONWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TONWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain

        let providers: [TONProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                TONProvider(node: nodeInfo, networkConfig: input.networkInput.tangemProviderConfig)
            }

        let transactionBuilder = TONTransactionBuilder(wallet: input.wallet)

        return try TONWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: .init(
                providers: providers,
                blockchain: blockchain
            )
        )
    }
}
