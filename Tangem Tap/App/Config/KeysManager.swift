//
//  KeysManager.swift
//  Tangem Tap
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
        let blockchairApiKey: String
        let blockcypherTokens: [String]
        let infuraProjectId: String
    }
    
    private let keysFileName = "config"
    
    private let keys: Keys
    
    var coinMarketKey: String {
        keys.coinMarketCapKey
    }
    
    var moonPayKeys: MoonPayKeys {
        MoonPayKeys(apiKey: keys.moonPayApiKey, secretApiKey: keys.moonPayApiSecretKey)
    }
    
    var blockchainConfig: BlockchainSdkConfig {
        BlockchainSdkConfig(blockchairApiKey: keys.blockchairApiKey,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId)
    }
    
    init() throws {
        keys = try JsonReader.readBundleFile(with: keysFileName, type: Keys.self)
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
