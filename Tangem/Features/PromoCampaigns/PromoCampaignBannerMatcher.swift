//
//  PromoCampaignBannerMatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromoCampaignBannerMatcher {
    static func isVisible(campaignId: Int?, campaigns: [PromoCampaign]) -> Bool {
        guard let campaignId else {
            return true
        }

        guard let campaign = campaigns.first(where: { $0.id == campaignId }) else {
            return false
        }

        return !campaign.isEnrolled
    }
}
