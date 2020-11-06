//
//  TangemTapWorkaroundsService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class WorkaroundsService {
    func isPayIDSupported(for card: Card) -> Bool {
        if let issuerName = card.cardData?.issuerName,
            issuerName == "start2coin" { //restrict payID for start2coin cards
            return false
        }
        
        return true
    }
    
    func isTopupSupported(for card: Card) -> Bool {
        if let issuerName = card.cardData?.issuerName,
            issuerName == "start2coin" { //restrict payID for start2coin cards
            return false
        }
        
        return true
    }
}
