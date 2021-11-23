//
//  AppConfig.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct AppConfig {
    var coinMarketCapApiKey: String {
        raw[AppConfig.Keys.coinMarketCapApiKey.rawValue] as! String
    }
    
    var moonPayApiKey: String {
        raw[AppConfig.Keys.moonPayApiKey.rawValue] as! String
    }
    
    var moonPaySecretApiKey: String {
        raw[AppConfig.Keys.moonPaySecretApiKey.rawValue] as! String
    }
    
    var isEnableMoonPay: Bool {
        raw[AppConfig.Keys.isEnableMoonPay.rawValue] as! Bool
    }
    
    var isEnablePayID: Bool {
		raw[AppConfig.Keys.isEnablePayID.rawValue] as! Bool
	}
	
	var isEnableTwinRecreation: Bool {
		raw[AppConfig.Keys.isEnableTwinRecreation.rawValue] as! Bool
	}
    
    private enum Keys: String {
        case coinMarketCapApiKey
        case moonPayApiKey
        case moonPaySecretApiKey
        case isEnableMoonPay
        case isEnablePayID
		case isEnableTwinRecreation
    }
    
    let raw: [String: Any]
    
    init() {
        let path = Bundle.main.path(forResource: "Config", ofType: "plist")!
        raw =  NSDictionary(contentsOfFile: path) as! Dictionary
    }
}
