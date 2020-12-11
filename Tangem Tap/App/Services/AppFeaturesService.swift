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
    func getFeatures(for card: Card) -> AppFeatures {
        if let issuerName = card.cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return .none
        }
        
        if let blockhainName = card.cardData?.blockchainName,
           blockhainName.lowercased() == "btc" {
            return .allExceptPayReceive
        }
        
		if card.isTwinCard {
            return .allExceptPayReceive
        }
        
        return .all
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
    static var all: Set<AppFeature> {
        return Set(Element.allCases)
    }
    
    static var none: Set<AppFeature> {
        return Set()
    }
    
    static var allExceptPayReceive: Set<AppFeature> {
        var features = all
        features.remove(.payIDReceive)
        return features
    }
}

typealias AppFeatures = Set<AppFeature>
