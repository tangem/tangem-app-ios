//
//  RateAppRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppRoutable: AnyObject {
    func openAppRateDialog(with viewModel: RateAppBottomSheetViewModel)
    func closeAppRateDialog()
    func openFeedbackMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openAppStoreReview()
}
