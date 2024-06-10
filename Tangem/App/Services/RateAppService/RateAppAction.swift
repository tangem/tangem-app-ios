//
//  RateAppAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Service to controller commands.
enum RateAppAction {
    case requestAppRate
    case dismissAppRate
    case openFeedbackMailWithEmailType(emailType: EmailType)
    case openAppStoreReview
}
