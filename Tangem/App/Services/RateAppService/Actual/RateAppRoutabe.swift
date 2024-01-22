//
//  RateAppRoutabe.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppRoutabe: AnyObject {
    func openAppRateDialog(with viewModel: RateAppBottomSheetViewModel)
    func openFeedbackMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openAppStoreReview()
}
