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
        StellarSDK.networkingUtil = StellarSDKNetworkingUtilImpl()

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

private class StellarSDKNetworkingUtilImpl: StellarSDKNetworkingUtil {
    private let session: URLSession

    init() {
        session = TangemTrustEvaluatorUtil.makeSession(configuration: .ephemeralConfiguration)
    }

    func evaluate(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return TangemTrustEvaluatorUtil.evaluate(challenge: challenge)
    }

    public func makeSession() -> URLSession {
        return session
    }
}
