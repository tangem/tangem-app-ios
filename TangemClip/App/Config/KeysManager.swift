//
//  KeysManager.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class KeysManager {
    
    struct Keys: Decodable {
        let coinMarketCapKey: String
        let blockchairApiKey: String
        let blockcypherTokens: [String]
        let infuraProjectId: String
    }
    
    private let keysFileName = "config"
    
    private let keys: Keys
    
    var coinMarketKey: String {
        keys.coinMarketCapKey
    }
    
    var blockchainConfig: BlockchainSdkConfig {
        BlockchainSdkConfig(blockchairApiKey: keys.blockchairApiKey,
                            blockcypherTokens: keys.blockcypherTokens,
                            infuraProjectId: keys.infuraProjectId)
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
