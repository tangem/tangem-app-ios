//
//  EmailConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct EmailConfig {
    let recipient: String
    let subject: String

    static var `default`: EmailConfig {
        .init(
            recipient: "support@tangem.com",
            subject: Localization.feedbackSubjectSupportTangem
        )
    }

    static var backupError: EmailConfig {
        .init(
            recipient: "support@tangem.com",
            subject: Localization.commonBackupError
        )
    }

    static func visaDefault(subject: VisaEmailSubject = .default) -> EmailConfig {
        let recipient = "pay@tangem.com"
        return .init(recipient: recipient, subject: subject.prefix)
    }

    static func paeraDefault(subject: PaeraEmailSubject) -> EmailConfig {
        let recipient = "support@paera.com"
        return .init(recipient: recipient, subject: subject.prefix)
    }
}

enum PaeraEmailSubject {
    case KYCRejected
    case regionUnavailable

    var prefix: String {
        switch self {
        case .KYCRejected:
            return "Tangem Pay - KYC rejected"
        case .regionUnavailable:
            return "Tangem Pay - Region unavailable"
        }
    }
}

enum VisaEmailSubject {
    case `default`
    case activation
    case generalHelp
    case payment
    case depositWithdrawal
    case failedToIssueCard
    case usdAccountGeneralHelp
    case usdAccountCloseAccount

    var prefix: String {
        let visaPrefix = "[Visa]"
        switch self {
        case .default, .generalHelp, .depositWithdrawal, .failedToIssueCard: return visaPrefix
        case .payment: return "\(visaPrefix) [PAYMENT]"
        case .activation: return "\(visaPrefix) [Activation]"
        case .usdAccountGeneralHelp, .usdAccountCloseAccount: return "\(visaPrefix) [USD ACCOUNT]"
        }
    }

    /// Support triages incoming mail by subject, so the newer messages stay in English regardless of the app language.
    var message: String {
        switch self {
        case .default, .activation: return Localization.feedbackSubjectSupport
        case .payment: return "Help"
        case .generalHelp, .usdAccountGeneralHelp: return "General help"
        case .depositWithdrawal: return "Deposit/withdrawal"
        case .failedToIssueCard: return "Failed to issue card"
        case .usdAccountCloseAccount: return "Close account"
        }
    }
}
