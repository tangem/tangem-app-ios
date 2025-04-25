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

    static func visaDefault(subject: VisaEmailSubject = .default) -> EmailConfig {
        let recipient = "pay@tangem.com"
        return .init(recipient: recipient, subject: subject.prefix)
    }
}

enum VisaEmailSubject {
    case `default`
    case dispute
    case activation

    var prefix: String {
        let visaPrefix = "[Visa]"
        switch self {
        case .default: return visaPrefix
        case .dispute: return "\(visaPrefix) [DISPUTE]"
        case .activation: return "\(visaPrefix) [Activation]"
        }
    }
}
