//
//  Config.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct Config {
    var coinMarketCapApiKey: String {
        raw[Config.Keys.coinMarketCapApiKey.rawValue] as! String
    }
    
    var moonPayApiKey: String {
        raw[Config.Keys.moonPayApiKey.rawValue] as! String
    }
    
    var moonPaySecretApiKey: String {
        raw[Config.Keys.moonPaySecretApiKey.rawValue] as! String
    }
    
    private enum Keys: String {
        case coinMarketCapApiKey
        case moonPayApiKey
        case moonPaySecretApiKey
    }
    
    let raw: [String: Any]
    
    init() {
        let path = Bundle.main.path(forResource: "Config", ofType: "plist")!
        raw =  NSDictionary(contentsOfFile: path) as! Dictionary
    }
}
