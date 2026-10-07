//
//  PromoCampaignFixtures.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

enum PromoCampaignFixtures {
    static func makeCampaign(id: Int, isEnrolled: Bool = false) -> PromoCampaign {
        let json = """
        {
          "id": \(id),
          "name": "campaign_\(id)",
          "alreadyEnrolled": \(isEnrolled),
          "content": { "campaignName": "Campaign \(id)", "publicDescription": [], "actionButtonName": "Join" },
          "properties": { "payoutNeeded": false, "matchMode": "strict" }
        }
        """
        let dto = try! JSONDecoder().decode(PromoCampaignsDTO.Promotion.self, from: Data(json.utf8))

        return PromoCampaignMapper().mapToPromoCampaign(from: dto)
    }
}
