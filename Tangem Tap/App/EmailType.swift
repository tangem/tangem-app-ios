//
//  EmailType.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import MessageUI

enum EmailType {
    case negativeRateAppFeedback, failedToScanCard, failedToSendTx, appFeedback
    
    var emailSubject: String {
        switch self {
        case .negativeRateAppFeedback: return "My suggestions"
        case .failedToScanCard: return "Can't scan a card"
        case .failedToSendTx: return "Can't send a transaction"
        case .appFeedback: return "Tangem Tap feedback"
        }
    }
    
    var emailPreface: String {
        switch self {
        case .negativeRateAppFeedback: return "Tell us what functions you are missing, and we will try to help you."
        case .failedToScanCard: return "Please tell us what card do you have?"
        case .failedToSendTx: return "Please tell us more about your issue. Every small detail can help."
        case .appFeedback: return "Hi Tangem,"
        }
    }
    
    var dataCollectionMessage: String {
        switch self {
        case .failedToScanCard: return ""
        default:
            return "Following information is optional. You can erase it if you don’t want to share it."
        }
        
    }
}
