//
//  RateAppAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum RateAppAction {
    /// An in-app (not provided by System or StoreKit) dialog/alert/sheet/etc.
    case openAppRateDialog
    case openFeedbackMailWithEmailType(emailType: EmailType)
    case openAppStoreReview
}
