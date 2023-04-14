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
            useBlockBookUtxoApis: FeatureProvider.isAvailable(.blockBookUtxoApis),
            nowNodesApiKey: keys.nowNodesApiKey,
            getBlockApiKey: keys.getBlockApiKey,
            kaspaSecondaryApiUrl: keys.kaspaSecondaryApiUrl,
            tronGridApiKey: keys.tronGridApiKey,
            tonCenterApiKeys: .init(mainnetApiKey: keys.tonCenterApiKey.mainnet, testnetApiKey: keys.tonCenterApiKey.testnet),
            // [REDACTED_TODO_COMMENT]
            quickNodeSolanaCredentials: .init(apiKey: keys.quiknodeApiKey, subdomain: keys.quiknodeSubdomain),
            quickNodeBscCredentials: .init(apiKey: keys.bscQuiknodeApiKey, subdomain: keys.bscQuiknodeSubdomain),
            blockscoutCredentials: keys.saltPay.blockscoutCredentials,
            defaultNetworkProviderConfiguration: .init(logger: .verbose, urlSessionConfiguration: .standart),
            networkProviderConfigurations: [.saltPay: .init(logger: .verbose, credentials: keys.saltPay.credentials)]
        )
    }

    var shopifyShop: ShopifyShop {
        keys.shopifyShop
    }

    var zendesk: ZendeskConfig {
        keys.zendesk
    }

    var amplitudeApiKey: String {
        keys.amplitudeApiKey
    }

    var saltPay: SaltPayConfiguration {
        keys.saltPay
    }

    var infuraProjectId: String {
        keys.infuraProjectId
    }

    var swapReferrerAccount: SwapReferrerAccount? {
        keys.swapReferrerAccount
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
        let getBlockApiKey: String
        let kaspaSecondaryApiUrl: String
        let tonCenterApiKey: TonCenterApiKeys
        let appsFlyer: AppsFlyerConfig
        let amplitudeApiKey: String
        let tronGridApiKey: String
        let quiknodeApiKey: String
        let quiknodeSubdomain: String
        let bscQuiknodeApiKey: String
        let bscQuiknodeSubdomain: String
        let shopifyShop: ShopifyShop
        let zendesk: ZendeskConfig
        let saltPay: SaltPayConfiguration
        let swapReferrerAccount: SwapReferrerAccount?
    }
}
