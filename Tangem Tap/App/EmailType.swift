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
    
    var sentEmailAlertTitle: String {
        switch self {
        case .negativeRateAppFeedback: return "alert_negative_app_rate_sent_title".localized
        default: return "alert_app_feedback_sent_title".localized
        }
    }
    
    var sentEmailAlertMessage: String {
        switch self {
        case .negativeRateAppFeedback: return "alert_negative_app_rate_sent_message".localized
        default: return "alert_app_feedback_sent_message".localized
        }
    }
    
    var failedToSendAlertTitle: String {
        "alert_failed_to_send_email_title".localized
    }
    
    func failedToSendAlertMessage(_ error: Error?) -> String {
        String(format: "alert_failed_to_send_email_message".localized, error?.localizedDescription ?? "Unknown error")
    }
    
}

struct EmailCollectedData {
    let type: EmailCollectedDataType
    let data: String
}

enum EmailCollectedDataType {
    case logs, card(CardData), send(SendData), wallet(WalletData)
    
    enum CardData: String {
        case cardId = "Card ID", firmwareVersion = "Firmware version", blockchain, token
    }
    
    enum SendData: String {
        case sourceAddress = "Source address", destinationAddress = "Destination address", amount, fee, transactionHex = "Transaction HEX"
    }
    
    enum WalletData: String {
        case walletAddress = "Wallet address", explorerLink = "Explorer link", signedHashes = "Signed hashes"
    }
    
    var title: String {
        switch self {
        case .logs: return "Logs: "
        case .card(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .send(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .wallet(let data): return data.rawValue + ": "
        }
    }
}
