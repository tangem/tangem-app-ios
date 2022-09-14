//
//  EmailType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum EmailType {
    case negativeRateAppFeedback
    case failedToScanCard
    case failedToSendTx
    case failedToPushTx
    case appFeedback(subject: String)

    var emailSubject: String {
        switch self {
        case .negativeRateAppFeedback: return "feedback_subject_rate_negative".localized
        case .failedToScanCard: return "feedback_subject_scan_failed".localized
        case .failedToSendTx: return "feedback_subject_tx_failed".localized
        case .appFeedback(let subject):
            return subject
        case .failedToPushTx: return  "feedback_subject_tx_push_failed".localized
        }
    }

    var emailPreface: String {
        switch self {
        case .negativeRateAppFeedback: return "feedback_preface_rate_negative".localized
        case .failedToScanCard: return "feedback_preface_scan_failed".localized
        case .failedToSendTx: return "feedback_preface_tx_failed".localized
        case .appFeedback: return "feedback_preface_support".localized
        case .failedToPushTx: return "feedback_preface_tx_push_failed".localized
        }
    }

    var dataCollectionMessage: String {
        switch self {
        case .failedToScanCard: return ""
        default:
            return "feedback_data_collection_message".localized
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

    static func separator(_ type: EmailCollectedDataType.SeparatorType) -> EmailCollectedData {
        EmailCollectedData(type: .separator(type), data: "")
    }
}

enum EmailCollectedDataType {
    case logs
    case card(CardData)
    case send(SendData)
    case wallet(WalletData)
    case error
    case separator(SeparatorType)
    case token(TokenData)

    enum CardData: String {
        case cardId = "Card ID"
        case firmwareVersion = "Firmware version"
        case cardBlockchain = "Card Blockchain"
        case blockchain
        case derivationPath = "Derivation path"
        case token
    }

    enum SendData: String {
        case sourceAddress = "Source address"
        case destinationAddress = "Destination address"
        case amount
        case fee
        case transactionHex = "Transaction HEX"
        case pushingTxHash = "Pushing Transaction Hash"
        case pushingFee = "Pushing Transaction New Fee"
    }

    enum WalletData: String {
        case walletAddress = "Wallet address"
        case explorerLink = "Explorer link"
        case signedHashes = "Signed hashes"
        case walletManagerHost = "Host"
        case outputsCount = "Outputs count"
        case derivationPath = "Derivation path"
    }

    enum TokenData: String {
        case contractAddress = "Contract address"
        case name = "Name"
        case tokens = "Tokens"
        case id = "ID"
    }

    enum SeparatorType: String {
        case dashes = "--------"
        case newLine = "\n"
    }

    var title: String {
        switch self {
        case .logs: return "Logs: "
        case .card(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .send(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .wallet(let data): return data.rawValue + ": "
        case .token(let data): return data.rawValue + ": "
        case .error: return "Error: "
        case .separator(let type): return type.rawValue
        }
    }
}
