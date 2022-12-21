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
        case .negativeRateAppFeedback: return L10n.feedbackSubjectRateNegative
        case .failedToScanCard: return L10n.feedbackSubjectScanFailed
        case .failedToSendTx: return L10n.feedbackSubjectTxFailed
        case .appFeedback(let subject):
            return subject
        case .failedToPushTx: return  L10n.feedbackSubjectTxPushFailed
        }
    }

    var emailPreface: String {
        switch self {
        case .negativeRateAppFeedback: return L10n.feedbackPrefaceRateNegative
        case .failedToScanCard: return L10n.feedbackPrefaceScanFailed
        case .failedToSendTx: return L10n.feedbackPrefaceTxFailed
        case .appFeedback: return L10n.feedbackPrefaceSupport
        case .failedToPushTx: return L10n.feedbackPrefaceTxFailed
        }
    }

    var dataCollectionMessage: String {
        switch self {
        case .failedToScanCard: return ""
        default:
            return L10n.feedbackDataCollectionMessage
        }
    }

    var sentEmailAlertTitle: String {
        switch self {
        case .negativeRateAppFeedback: return L10n.alertNegativeAppRateSentTitle
        default: return L10n.alertAppFeedbackSentTitle
        }
    }

    var sentEmailAlertMessage: String {
        switch self {
        case .negativeRateAppFeedback: return L10n.alertNegativeAppRateSentMessage
        default: return L10n.alertAppFeedbackSentMessage
        }
    }

    var failedToSendAlertTitle: String {
        L10n.alertFailedToSendEmailTitle
    }

    func failedToSendAlertMessage(_ error: Error?) -> String {
        L10n.alertFailedToSendTransactionMessage(error?.localizedDescription ?? "Unknown error")
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
        case userWalletId
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
