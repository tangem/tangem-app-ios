//
//  PromoCampaign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PromoCampaign: Equatable {
    let id: Int
    let name: String
    let isEnrolled: Bool
    let content: PromoCampaignContent
    let isPayoutNeeded: Bool
    let payoutTokens: [CampaignEligibleToken]
    let matchMode: MatchMode
}

extension PromoCampaign {
    enum MatchMode: Equatable {
        case strict
        case linkedWallet
    }
}
