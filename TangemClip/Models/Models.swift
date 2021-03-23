//
//  Models.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips

class CardViewModel: ObservableObject {
    var cardInfo: CardInfo
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }
    
    func getCardInfo() {
        
    }
}

class Analytics {
    enum Event: String {
        case cardIsScanned = "card_is_scanned"
        case transactionIsSent = "transaction_is_sent"
        case readyToScan = "ready_to_scan"
        case displayRateAppWarning = "rate_app_warning_displayed"
        case negativeRateAppFeedback = "negative_rate_app_feedback"
        case positiveRateAppFeedback = "positive_rate_app_feedback"
        case dismissRateAppWarning = "dismiss_rate_app_warning"
    }
    
    static func log(error: Error) {
        print("LOGGING ERRORRRRRR!RR!R!!Rrrr: ", error)
    }
    
    static func logScan(card: Card) {
        print("This is card", card)
    }
    
    static func log(event: Event) {
        print("ALARM!ALRAMRA. This is event", event.rawValue)
    }
}
