//
//  KeysManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
struct MoonPayKeys {
    let apiKey: String
    let secretApiKey: String
}

class KeysManager {
    
    struct Keys: Decodable {
        let coinMarketCapKey: String
        let moonPayApiKey: String
        let moonPayApiSecretKey: String
        let onramperApiKey: String
        let blockchairApiKey: String
        let blockcypherTokens: [String]
        let infuraProjectId: String
        let appsFlyerDevKey: String
        let shopifyShop: ShopifyShop
    }
    
    private let keysFileName = "config"
    
    private let keys: Keys
    
    var coinMarketKey: String {
        keys.coinMarketCapKey
    }
    
    var appsFlyerDevKey: String {
        keys.appsFlyerDevKey
    }
    
    var moonPayKeys: MoonPayKeys {
        MoonPayKeys(apiKey: keys.moonPayApiKey, secretApiKey: keys.moonPayApiSecretKey)
    }
    
    var onramperApiKey: String {
        keys.onramperApiKey
    }
    
    var blockchainConfig: BlockchainSdkConfig {
        BlockchainSdkConfig(blockchairApiKey: keys.blockchairApiKey,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId)
    }
    
    var shopifyShop: ShopifyShop {
        keys.shopifyShop
    }
    
    init() throws {
        keys = try JsonUtils.readBundleFile(with: keysFileName, type: Keys.self)
        if keys.blockchairApiKey.isEmpty ||
            keys.blockcypherTokens.isEmpty ||
            keys.infuraProjectId.isEmpty {
            throw NSError(domain: "Empty keys in config file", code: -9998, userInfo: nil)
        }
        
        if keys.blockcypherTokens.first(where: { $0.isEmpty }) != nil {
            throw NSError(domain: "One of blockcypher tokens is empty", code: -10001, userInfo: nil)
        }
    }
}
