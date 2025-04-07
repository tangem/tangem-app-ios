//
//  StellarWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import TangemNetworkUtils

struct StellarWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        StellarSDK.forcedCT = ForcedCTServerTrustEvaluator.shouldForceCT

        return StellarWalletManager(wallet: input.wallet).then {
            let blockchain = input.wallet.blockchain
            let providers: [StellarNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig).resolveProviders(apiInfos: input.networkInput.apiInfo) { nodeInfo, _ in
                StellarNetworkProvider(
                    isTestnet: blockchain.isTestnet,
                    stellarSdk: .init(withHorizonUrl: nodeInfo.link)
                )
            }

            $0.txBuilder = StellarTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.wallet.blockchain.isTestnet)
            $0.networkService = StellarNetworkService(providers: providers)
        }
    }
}
