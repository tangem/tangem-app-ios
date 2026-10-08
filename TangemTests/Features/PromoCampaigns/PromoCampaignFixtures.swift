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
    static func makeCampaign(
        id: Int,
        isEnrolled: Bool = false,
        isPayoutNeeded: Bool = false,
        matchMode: PromoCampaignsDTO.MatchMode = .strict
    ) -> PromoCampaign {
        let payoutTokens = isPayoutNeeded ? usdcPayoutTokenJSON : ""
        let json = """
        {
          "id": \(id),
          "name": "campaign_\(id)",
          "alreadyEnrolled": \(isEnrolled),
          "content": { "campaignName": "Campaign \(id)", "publicDescription": [], "actionButtonName": "Join" },
          "properties": { "payoutNeeded": \(isPayoutNeeded), "matchMode": "\(matchMode.rawValue)"\(payoutTokens) }
        }
        """
        let dto = try! JSONDecoder().decode(PromoCampaignsDTO.Promotion.self, from: Data(json.utf8))

        return PromoCampaignMapper().mapToPromoCampaign(from: dto)
    }

    private static let usdcPayoutTokenJSON = """
    , "payoutTokens": [{ "tokenAddress": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "networkId": "ethereum", "tokenSymbol": "USDC", "tokenName": "USD Coin", "tokenId": "usd-coin", "decimals": 6 }]
    """
}
