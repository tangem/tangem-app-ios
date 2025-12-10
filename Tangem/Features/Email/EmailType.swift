//
//  EmailType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EmailType {
    case negativeRateAppFeedback
    case failedToScanCard
    case failedToSendTx
    case failedToPushTx
    case appFeedback(subject: String)
    case activatedCard
    case attestationFailed
    case visaFeedback(subject: VisaEmailSubject)
    case walletConnectUntypedError(formattedErrorCode: String)

    var emailSubject: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.feedbackSubjectRateNegative
        case .failedToScanCard: return Localization.feedbackSubjectScanFailed
        case .failedToSendTx: return Localization.feedbackSubjectTxFailed
        case .appFeedback(let subject):
            return subject
        case .failedToPushTx: return Localization.feedbackSubjectTxPushFailed
        case .activatedCard: return Localization.feedbackSubjectPreActivatedWallet
        case .attestationFailed: return "Card attestation failed"
        case .visaFeedback(let subject):
            return "\(subject.prefix) \(Localization.feedbackSubjectSupport)"
        case .walletConnectUntypedError:
            return Localization.emailSubjectWcError
        }
    }

    var emailPreface: String? {
        switch self {
        case .negativeRateAppFeedback: return Localization.feedbackPrefaceRateNegative
        case .failedToScanCard: return Localization.feedbackPrefaceScanFailed
        case .failedToSendTx: return Localization.feedbackPrefaceTxFailed
        case .failedToPushTx: return Localization.feedbackPrefaceTxFailed
        case .appFeedback,
             .activatedCard,
             .attestationFailed:
            return Localization.feedbackPrefaceSupport
        case .walletConnectUntypedError(let formattedErrorCode):
            return Localization.emailPrefaceWcError(formattedErrorCode)
        case .visaFeedback:
            return nil
        }
    }

    var sentEmailAlertTitle: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.alertNegativeAppRateSentTitle
        default: return Localization.alertAppFeedbackSentTitle
        }
    }

    var sentEmailAlertMessage: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.alertNegativeAppRateSentMessage
        default: return Localization.alertAppFeedbackSentMessage
        }
    }

    var failedToSendAlertTitle: String {
        Localization.alertFailedToSendEmailTitle
    }

    func failedToSendAlertMessage(_ error: Error?) -> String {
        Localization.alertFailedToSendTransactionMessage(error?.localizedDescription ?? "Unknown error")
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
    case staking(StakingData)
    case wallet(WalletData)
    case error
    case separator(SeparatorType)
    case token(TokenData)
    case visaDisputeTransaction(VisaDisputeTransactionData)
    case mobileWallet(MobileWalletData)

    enum CardData: String {
        case cardId = "Card ID"
        case firmwareVersion = "Firmware version"
        case cardBlockchain = "Card Blockchain"
        case blockchain
        case derivationPath = "Derivation path"
        case token
        case userWalletId
        case linkedCardsCount = "Linked cards count"
        case backupCardsCount = "Backup cards count"
    }

    enum SendData: String {
        case sourceAddress = "Source address"
        case destinationAddress = "Destination address"
        case amount
        case fee
        case isFeeIncluded = "Is fee included"
        case transactionHex = "Transaction HEX"
        case pushingTxHash = "Pushing Transaction Hash"
        case pushingFee = "Pushing Transaction New Fee"
    }

    enum StakingData: String {
        case validatorName = "Validator Name"
        case validatorAddress = "Validator Address"
        case stakingAction = "Staking Action"
    }

    enum WalletData: String {
        case walletAddress = "Wallet address"
        case explorerLink = "Explorer link"
        case signedHashes = "Signed hashes"
        case walletManagerHost = "Host"
        case exceptionWalletManagerHost = "Exception Host"
        case outputsCount = "Outputs count"
        case derivationPath = "Derivation path"
        case hasSeedPhrase = "Has seed phrase"
    }

    enum TokenData: String {
        case contractAddress = "Contract address"
        case name = "Name"
        case id = "ID"
        case decimals = "Decimals"
    }

    enum SeparatorType: String {
        case dashes = "--------"
        case newLine = "\n"
    }

    enum VisaDisputeTransactionData: String {
        case id = "ID"
        case type = "Type"
        case status = "Status"
        case blockchainAmount = "Blockchain amount"
        case blockchainCoinName = "Blockchain coin name"
        case transactionAmount = "Transaction amount"
        case currencyCode = "Currency code"
        case billingAmount = "Billing amount"
        case billingCurrencyCode = "Billing currency code"
        case merchantName = "Merchant name"
        case merchantCity = "Merchant city"
        case merchantCountryCode = "Merchant country code"
        case merchantCategoryCode = "Merchant category code"
        case errorCode = "Error code"
        case date = "Date"
        case transactionHash = "Transaction hash"
        case transactionStatus = "Transaction status"
        case requests = "Blockchain requests"
    }

    enum MobileWalletData: String {
        case hasBackup = "Mobile Wallet is backed up"
        case hasAccessCode = "Mobile Wallet has access code"
    }

    var title: String {
        switch self {
        case .logs: return "Logs: "
        case .card(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .send(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .staking(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .wallet(let data): return data.rawValue + ": "
        case .token(let data): return data.rawValue + ": "
        case .error: return "Error: "
        case .separator(let type): return type.rawValue
        case .visaDisputeTransaction(let data): return data.rawValue + ": "
        case .mobileWallet(let data): return data.rawValue + ": "
        }
    }
}
