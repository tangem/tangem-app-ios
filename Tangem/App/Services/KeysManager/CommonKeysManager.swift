//
//  KeysManager.swift
//  Tangem
//
//  Created by Andrew Son on 07/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CommonKeysManager {
    private let keysFileName = "config"
    private let keys: Keys
    
    init() {
        do {
            let keys = try JsonUtils.readBundleFile(with: keysFileName, type: Keys.self)
            
            if keys.blockchairApiKey.isEmpty ||
                keys.blockcypherTokens.isEmpty ||
                keys.infuraProjectId.isEmpty {
                throw NSError(domain: "Empty keys in config file", code: -9998, userInfo: nil)
            }
            
            if keys.blockcypherTokens.first(where: { $0.isEmpty }) != nil {
                throw NSError(domain: "One of blockcypher tokens is empty", code: -10001, userInfo: nil)
            }
            
            self.keys = keys
        } catch {
            self.keys = Keys.empty
        }
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
        BlockchainSdkConfig(blockchairApiKey: keys.blockchairApiKey,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId,
                            tronGridApiKey: keys.tronGridApiKey)
    }
    
    var shopifyShop: ShopifyShop {
        keys.shopifyShop
    }
}

extension CommonKeysManager {
    struct Keys: Decodable {
        let moonPayApiKey: String
        let moonPayApiSecretKey: String
        let mercuryoWidgetId: String
        let mercuryoSecret: String
        let blockchairApiKey: String
        let blockcypherTokens: [String]
        let infuraProjectId: String
        let appsFlyerDevKey: String
        let tronGridApiKey: String
        let shopifyShop: ShopifyShop
        
        fileprivate static var empty: Keys {
            .init(moonPayApiKey: "", moonPayApiSecretKey: "", mercuryoWidgetId: "", mercuryoSecret: "", blockchairApiKey: "",
                  blockcypherTokens: [], infuraProjectId: "", appsFlyerDevKey: "", tronGridApiKey: "",
                  shopifyShop: .init(domain: "", storefrontApiKey: "", merchantID: ""))
        }
    }
}
