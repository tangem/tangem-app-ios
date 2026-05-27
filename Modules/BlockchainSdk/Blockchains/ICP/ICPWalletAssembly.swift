//
//  ICPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import IcpKit
import TangemSdk

struct ICPWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> any WalletManager {
        let blockchain = input.wallet.blockchain

        let providers: [ICPNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                ICPNetworkProvider(
                    node: nodeInfo,
                    networkConfig: input.networkInput.tangemProviderConfig,
                    responseParser: ICPResponseParser()
                )
            }

        let transactionBuilder = ICPTransactionBuilder(
            decimalValue: input.wallet.blockchain.decimalValue,
            publicKey: input.wallet.publicKey.blockchainKey,
            nonce: try CryptoUtils.icpNonce()
        )

        return ICPWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: ICPNetworkService(
                providers: providers,
                blockchain: input.wallet.blockchain
            )
        )
    }
}
