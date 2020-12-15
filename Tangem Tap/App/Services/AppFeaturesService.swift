//
//  AppFeaturesService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AppFeaturesService {
	
	let config: AppConfig
	
	init(config: AppConfig) {
		self.config = config
	}
	
    func getFeatures(for card: Card) -> AppFeatures {
        if let issuerName = card.cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return .none
        }
        
		var features = AppFeatures.all
		
        if card.cardData?.blockchainName?.lowercased() == "btc" ||
			card.isTwinCard ||
			!config.isWalletPayIdEnabled {
			features.remove(.payIDReceive)
        }
		
		if !config.isSendingToPayIdEnabled {
			features.remove(.payIDSend)
		}
		
		if !config.isEnableMoonPay {
			features.remove(.topup)
		}
        
        return features
    }
    
    func isTopupSupported(for card: Card) -> Bool {
        if getFeatures(for: card).contains(.topup) {
            return true
        }
        
        return false
    }
}


enum AppFeature: String, Option {
    case payIDReceive
    case payIDSend
    case topup
    case pins
    case linkedTerminal
}

extension Set where Element == AppFeature {
    static var all: AppFeatures {
        return Set(Element.allCases)
    }
    
    static var none: AppFeatures {
        return Set()
    }
    
    static var allExceptPayReceive: AppFeatures {
        var features = all
        features.remove(.payIDReceive)
        return features
    }
	
	static func allExcept(_ set: AppFeatures) -> AppFeatures {
		var features = all
		set.forEach { features.remove($0) }
		return features
	}
}

typealias AppFeatures = Set<AppFeature>
