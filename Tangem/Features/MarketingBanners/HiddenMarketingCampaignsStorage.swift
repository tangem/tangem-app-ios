//
//  HiddenMarketingCampaignsStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

enum HiddenMarketingCampaignsStorage {
    static var hiddenCampaignIdsPublisher: AnyPublisher<Set<Int>, Never> {
        AppSettings.shared.$hiddenMarketingCampaignIds
            .map { Set($0) }
            .eraseToAnyPublisher()
    }

    static func hide(campaignId: Int) {
        guard !AppSettings.shared.hiddenMarketingCampaignIds.contains(campaignId) else {
            return
        }

        AppSettings.shared.hiddenMarketingCampaignIds.append(campaignId)
    }
}
