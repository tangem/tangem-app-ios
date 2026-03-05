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

        let blockchain = input.wallet.blockchain
        let apiList = APIList(dictionaryLiteral: (blockchain.networkId, input.networkInput.apiInfo))

        let serviceFactory = WalletNetworkServiceFactory(
            blockchainSdkKeysConfig: input.networkInput.keysConfig,
            tangemProviderConfig: input.networkInput.tangemProviderConfig,
            apiList: apiList
        )

        let networkService: StellarNetworkService = try serviceFactory.makeServiceWithType(for: blockchain)

        return StellarWalletManager(wallet: input.wallet).then {
            $0.txBuilder = StellarTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: blockchain.isTestnet)
            $0.networkService = networkService
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
