//
// SuiWalletAssembly.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct SuiWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> any WalletManager {
        let providers = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                SuiNetworkProvider(
                    node: nodeInfo,
                    networkConfiguration: input.networkInput.tangemProviderConfig
                )
            }

        let transactionBuilder = SuiTransactionBuilder(
            walletAddress: input.wallet.address,
            publicKey: input.wallet.publicKey,
            decimalValue: input.wallet.blockchain.decimalValue
        )

        return SuiWalletManager(wallet: input.wallet, networkService: SuiNetworkService(providers: providers), transactionBuilder: transactionBuilder)
    }
}
