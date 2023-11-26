//
//  KeysManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CommonKeysManager {
    private let keys: Keys

    init() throws {
        keys = try JsonUtils.readBundleFile(with: AppEnvironment.current.configFileName, type: CommonKeysManager.Keys.self)
    }
}

extension CommonKeysManager: KeysManager {
    var appsFlyer: AppsFlyerConfig {
        keys.appsFlyer
    }

    var moonPayKeys: MoonPayKeys {
        MoonPayKeys(apiKey: keys.moonPayApiKey, secretApiKey: keys.moonPayApiSecretKey)
    }

    var mercuryoWidgetId: String {
        keys.mercuryoWidgetId
    }

    var mercuryoSecret: String {
        keys.mercuryoSecret
    }

    var blockchainConfig: BlockchainSdkConfig {
        BlockchainSdkConfig(
            blockchairApiKeys: keys.blockchairApiKeys,
            blockcypherTokens: keys.blockcypherTokens,
            infuraProjectId: keys.infuraProjectId,
            nowNodesApiKey: keys.nowNodesApiKey,
            getBlockCredentials: .init(keys.getBlockAccessTokens),
            kaspaSecondaryApiUrl: keys.kaspaSecondaryApiUrl,
            tronGridApiKey: keys.tronGridApiKey,
            tonCenterApiKeys: .init(mainnetApiKey: keys.tonCenterApiKey.mainnet, testnetApiKey: keys.tonCenterApiKey.testnet),
            fireAcademyApiKeys: .init(mainnetApiKey: keys.chiaFireAcademyApiKey, testnetApiKey: keys.chiaFireAcademyApiKey),
            chiaTangemApiKeys: .init(mainnetApiKey: keys.chiaTangemApiKey),
            // [REDACTED_TODO_COMMENT]
            quickNodeSolanaCredentials: .init(apiKey: keys.quiknodeApiKey, subdomain: keys.quiknodeSubdomain),
            quickNodeBscCredentials: .init(apiKey: keys.bscQuiknodeApiKey, subdomain: keys.bscQuiknodeSubdomain),
            blockscoutCredentials: .init(login: "", password: ""), // used for saltpay tx history
            defaultNetworkProviderConfiguration: .init(logger: .verbose, urlSessionConfiguration: .standart),
            networkProviderConfigurations: [:]
        )
    }

    var tangemComAuthorization: String? {
        keys.tangemComAuthorization
    }

    var sprinklr: SprinklrConfig {
        keys.sprinklr
    }

    var amplitudeApiKey: String {
        keys.amplitudeApiKey
    }

    var utorgSID: String {
        "tangemTEST"
    }

    var infuraProjectId: String {
        keys.infuraProjectId
    }

    var swapReferrerAccount: SwapReferrerAccount? {
        keys.swapReferrerAccount
    }

    var walletConnectProjectId: String {
        keys.walletConnectProjectId
    }

    var tangemExpressApiKey: String {
        keys.tangemExpressApiKey
    }
}

extension CommonKeysManager {
    struct Keys: Decodable {
        let moonPayApiKey: String
        let moonPayApiSecretKey: String
        let mercuryoWidgetId: String
        let mercuryoSecret: String
        let blockchairApiKeys: [String]
        let blockcypherTokens: [String]
        let infuraProjectId: String
        let nowNodesApiKey: String
        let getBlockAccessTokens: [String: GetBlockAccessToken]
        let kaspaSecondaryApiUrl: String
        let tonCenterApiKey: TonCenterApiKeys
        let chiaFireAcademyApiKey: String
        let chiaTangemApiKey: String
        let appsFlyer: AppsFlyerConfig
        let amplitudeApiKey: String
        let tronGridApiKey: String
        let quiknodeApiKey: String
        let quiknodeSubdomain: String
        let bscQuiknodeApiKey: String
        let bscQuiknodeSubdomain: String
        let tangemComAuthorization: String?
        let swapReferrerAccount: SwapReferrerAccount?
        let walletConnectProjectId: String
        let sprinklr: SprinklrConfig
        let tangemExpressApiKey: String
    }
}
