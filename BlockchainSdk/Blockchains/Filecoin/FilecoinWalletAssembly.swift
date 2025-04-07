//
//  FilecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        FilecoinWalletManager(
            wallet: input.wallet,
            networkService: FilecoinNetworkService(
                providers: APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
                    .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                        FilecoinNetworkProvider(
                            node: nodeInfo,
                            configuration: input.networkInput.tangemProviderConfig
                        )
                    }
            ),
            transactionBuilder: try FilecoinTransactionBuilder(publicKey: input.wallet.publicKey)
        )
    }
}
