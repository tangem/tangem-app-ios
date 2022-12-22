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
        self.keys = try JsonUtils.readBundleFile(with: AppEnvironment.current.configFileName, type: CommonKeysManager.Keys.self)
    }
}

extension CommonKeysManager: KeysManager {
    var appsFlyerDevKey: String {
        keys.appsFlyerDevKey
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
        BlockchainSdkConfig(blockchairApiKeys: keys.blockchairApiKeys,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId,
                            tronGridApiKey: keys.tronGridApiKey,
                            quiknodeApiKey: keys.quiknodeApiKey,
                            quiknodeSubdomain: keys.quiknodeSubdomain,
                            defaultNetworkProviderConfiguration: .init(logger: .verbose, urlSessionConfiguration: .standart),
                            networkProviderConfigurations: [.saltPay: .init(logger: .verbose, credentials: keys.saltPay.credentials)])
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
        let appsFlyerDevKey: String
        let amplitudeApiKey: String
        let tronGridApiKey: String
        let quiknodeApiKey: String
        let quiknodeSubdomain: String
        let shopifyShop: ShopifyShop
        let zendesk: ZendeskConfig
        let saltPay: SaltPayConfiguration
    }
}
