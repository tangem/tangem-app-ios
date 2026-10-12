//
//  PromoCampaignAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PromoCampaignAnalyticsLogging {
    func log(_ event: PromoCampaignAnalyticsEvent, userWalletId: UserWalletId)
}

struct CommonPromoCampaignAnalyticsLogger: PromoCampaignAnalyticsLogging {
    func log(_ event: PromoCampaignAnalyticsEvent, userWalletId: UserWalletId) {
        Analytics.log(event: event.event, params: event.params, contextParams: .userWallet(userWalletId))
    }
}
