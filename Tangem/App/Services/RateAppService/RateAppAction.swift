//
//  RateAppAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum RateAppAction {
    case requestAppRate
    case dismissAppRate
    case openFeedbackMailWithEmailType(emailType: EmailType)
    case openAppStoreReview
}
