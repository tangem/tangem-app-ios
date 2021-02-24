//
//  Analytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import TangemSdk

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
    
    enum ParameterKey: String {
        case blockchain = "blockchain"
        case batchId = "batch_id"
        case firmware = "firmware"
    }
    
    static func log(event: Event) {
        FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: nil)
    }
    
    static func logScan(card: Card) {
        let blockchainName = card.cardData?.blockchainName ?? ""
        let params = [ParameterKey.blockchain.rawValue: blockchainName,
                      ParameterKey.batchId.rawValue: card.cardData?.batchId ?? "",
					  ParameterKey.firmware.rawValue: card.firmwareVersion?.version ?? ""]
        
        FirebaseAnalytics.Analytics.logEvent(Event.cardIsScanned.rawValue, parameters: params)
        Crashlytics.crashlytics().setCustomValue(blockchainName, forKey: ParameterKey.blockchain.rawValue)
    }
    
    static func logTx(blockchainName: String?) {
          FirebaseAnalytics.Analytics.logEvent(Event.transactionIsSent.rawValue,
                                               parameters: [ParameterKey.blockchain.rawValue: blockchainName ?? ""])
    }
    
    static func log(error: Error) {
        if case .userCancelled = error.toTangemSdkError() {
            return
        }
        
        Crashlytics.crashlytics().record(error: error)
    }
}
