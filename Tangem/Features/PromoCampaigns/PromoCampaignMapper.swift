//
//  PromoCampaignMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PromoCampaignMapper {
    private let contentMapper = PromoCampaignContentMapper()
    private let tokenMapper = CampaignEligibleTokenMapper()

    func mapToPromoCampaign(from dto: PromoCampaignsDTO.Promotion) -> PromoCampaign {
        let payoutTokens = dto.properties.payoutTokens ?? []

        return PromoCampaign(
            id: dto.id,
            name: dto.name,
            isEnrolled: dto.alreadyEnrolled,
            content: contentMapper.map(dto.content, payoutTokens: payoutTokens),
            isPayoutNeeded: dto.properties.payoutNeeded,
            payoutTokens: payoutTokens.map(tokenMapper.map)
        )
    }
}
