//
//  TezosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct TezosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain
        return try TezosWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: blockchain.curve)

            let linkResolver = APINodeInfoResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            let providers: [TezosJsonRpcProvider] = input.networkInput.apiInfo.compactMap {
                guard let nodeInfo = linkResolver.resolve(for: $0) else {
                    return nil
                }

                return TezosJsonRpcProvider(nodeInfo: nodeInfo, configuration: input.networkInput.tangemProviderConfig)
            }

            $0.networkService = TezosNetworkService(
                providers: providers
            )
        }
    }
}
