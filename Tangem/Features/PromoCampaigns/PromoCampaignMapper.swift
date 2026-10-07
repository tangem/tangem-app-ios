//
//  PromoCampaignMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PromoCampaignMapper {
    func mapToPromoCampaign(from dto: PromoCampaignsDTO.Promotion) -> PromoCampaign {
        PromoCampaign(id: dto.id, name: dto.name, isEnrolled: dto.alreadyEnrolled)
    }
}
