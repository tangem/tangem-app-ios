//
//  KeysManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

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

    var blockchainSdkKeysConfig: BlockchainSdkKeysConfig {
        BlockchainSdkKeysConfig(
            blockchairApiKeys: keys.blockchairApiKeys,
            blockcypherTokens: keys.blockcypherTokens,
            infuraProjectId: keys.infuraProjectId,
            nowNodesApiKey: keys.nowNodesApiKey,
            getBlockCredentials: .init(keys.getBlockAccessTokens),
            kaspaSecondaryApiUrl: keys.kaspaSecondaryApiUrl,
            tronGridApiKey: keys.tronGridApiKey,
            hederaArkhiaApiKey: keys.hederaArkhiaKey,
            etherscanApiKey: keys.etherscanApiKey,
            koinosProApiKey: keys.koinosProApiKey,
            tonCenterApiKeys: .init(mainnetApiKey: keys.tonCenterApiKey.mainnet, testnetApiKey: keys.tonCenterApiKey.testnet),
            fireAcademyApiKeys: .init(mainnetApiKey: keys.chiaFireAcademyApiKey, testnetApiKey: keys.chiaFireAcademyApiKey),
            chiaTangemApiKeys: .init(mainnetApiKey: keys.chiaTangemApiKey),
            // [REDACTED_TODO_COMMENT]
            quickNodeSolanaCredentials: .init(apiKey: keys.quiknodeApiKey, subdomain: keys.quiknodeSubdomain),
            quickNodeBscCredentials: .init(apiKey: keys.bscQuiknodeApiKey, subdomain: keys.bscQuiknodeSubdomain),
            quickNodePlasmaCredentials: .init(apiKey: keys.quiknodePlasmaApiKey, subdomain: keys.quiknodePlasmaSubdomain),
            bittensorDwellirKey: keys.bittensorDwellirKey,
            dwellirApiKey: keys.dwellirApiKey,
            bittensorOnfinalityKey: keys.bittensorOnfinalityKey,
            tangemAlephiumApiKey: keys.alephiumTangemApiKey,
            blinkApiKey: keys.blinkApiKey,
            tatumApiKey: keys.tatumApiKey,
            yieldModuleApiKey: keys.yieldModuleApiKey
            // [REDACTED_TODO_COMMENT]
//            gaslessTransactionsApiKey: keys.gaslessTransactionsApiKey
        )
    }

    var tangemComAuthorization: String? {
        keys.tangemComAuthorization
    }

    var amplitudeApiKey: String {
        keys.amplitudeApiKey
    }

    var appsFlyerConfig: AppsFlyerConfig {
        keys.appsFlyer
    }

    var utorgSID: String {
        "tangemTEST"
    }

    var infuraProjectId: String {
        keys.infuraProjectId
    }

    var expressKeys: ExpressKeys {
        keys.express
    }

    var devExpressKeys: ExpressKeys? {
        keys.devExpress
    }

    var walletConnectProjectId: String {
        keys.walletConnectProjectId
    }

    var stakeKitKey: String {
        keys.stakeKitApiKey
    }

    var moralisAPIKey: String {
        keys.moralisApiKey
    }

    var blockaidAPIKey: String {
        keys.blockaidApiKey
    }

    var tangemApiKey: String {
        keys.tangemApiKey
    }

    var tangemApiKeyDev: String {
        keys.tangemApiKeyDev
    }

    var tangemApiKeyStage: String {
        keys.tangemApiKeyStage
    }

    var yieldModuleApiKey: String {
        keys.yieldModuleApiKey
    }

    var yieldModuleApiKeyDev: String {
        keys.yieldModuleApiKeyDev
    }

    var p2pApiKeys: P2PAPIKeys {
        keys.p2pApiKey
    }

    var bffStaticToken: String {
        keys.bffStaticToken
    }

    // [REDACTED_TODO_COMMENT]
//    var gaslessTransactionsApiKey: String {
//        keys.gaslessTransactionsApiKey
//    }
//
//    var gaslessTransactionsApiKeyDev: String {
//        keys.gaslessTransactionsApiKeyDev
//    }
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
        let getBlockAccessTokens: [String: [String: String]]
        let kaspaSecondaryApiUrl: String
        let tonCenterApiKey: TonCenterApiKeys
        let chiaFireAcademyApiKey: String
        let chiaTangemApiKey: String
        let appsFlyer: AppsFlyerConfig
        let amplitudeApiKey: String
        let tronGridApiKey: String
        let hederaArkhiaKey: String
        let quiknodeApiKey: String
        let quiknodeSubdomain: String
        let bscQuiknodeApiKey: String
        let bscQuiknodeSubdomain: String
        let quiknodePlasmaApiKey: String
        let quiknodePlasmaSubdomain: String
        let etherscanApiKey: String
        let koinosProApiKey: String
        let tangemComAuthorization: String?
        let walletConnectProjectId: String
        let express: ExpressKeys
        let devExpress: ExpressKeys?
        let stakeKitApiKey: String
        let bittensorDwellirKey: String
        let dwellirApiKey: String
        let bittensorOnfinalityKey: String
        let alephiumTangemApiKey: String
        let moralisApiKey: String
        let blockaidApiKey: String
        let tangemApiKey: String
        let tangemApiKeyDev: String
        let tangemApiKeyStage: String
        let blinkApiKey: String
        let tatumApiKey: String
        let yieldModuleApiKey: String
        let yieldModuleApiKeyDev: String
        let p2pApiKey: P2PAPIKeys
        let bffStaticToken: String
        // [REDACTED_TODO_COMMENT]
//        let gaslessTransactionsApiKey: String = ""
//        let gaslessTransactionsApiKeyDev: String = ""
    }
}
