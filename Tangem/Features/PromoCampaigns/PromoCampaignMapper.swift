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
            payoutTokens: payoutTokens.map(tokenMapper.map),
            matchMode: mapToMatchMode(dto.properties.matchMode)
        )
    }
}

// MARK: - Private

private extension PromoCampaignMapper {
    func mapToMatchMode(_ matchMode: PromoCampaignsDTO.MatchMode) -> PromoCampaign.MatchMode {
        switch matchMode {
        case .strict:
            return .strict
        case .linkedWallet:
            return .linkedWallet
        }
    }
}
