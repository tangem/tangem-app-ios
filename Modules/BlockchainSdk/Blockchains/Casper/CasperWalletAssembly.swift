//
//  CasperWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CasperWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        CasperWalletManager(
            wallet: input.wallet,
            networkService: CasperNetworkService(
                providers: APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
                    .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                        CasperNetworkProvider(
                            node: nodeInfo,
                            configuration: input.networkInput.tangemProviderConfig
                        )
                    },
                blockchainDecimalValue: input.wallet.blockchain.decimalValue
            ),
            transactionBuilder: CasperTransactionBuilder(
                curve: input.wallet.blockchain.curve,
                blockchainDecimalValue: input.wallet.blockchain.decimalValue
            )
        )
    }
}
