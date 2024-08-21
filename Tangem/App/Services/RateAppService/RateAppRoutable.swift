//
//  RateAppRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppRoutable: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openAppStoreReview()
}
