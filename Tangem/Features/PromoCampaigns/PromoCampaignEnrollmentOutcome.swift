//
//  PromoCampaignEnrollmentOutcome.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PromoCampaignEnrollmentOutcome: Equatable {
    case enrolled([PromoCampaignEnrollment])
    case alreadyEnrolled([PromoCampaignEnrollment])
    case partiallyEnrolled(enrolled: [PromoCampaignEnrollment], alreadyEnrolled: [PromoCampaignEnrollment])
    case unavailable
    case temporarilyUnavailable
    case failed
}

struct PromoCampaignEnrollment: Equatable {
    let userWalletId: UserWalletId
    let payout: PromoCampaignPayout?
}

struct PromoCampaignPayout: Equatable {
    let userAddress: String
    let tokenAddress: String
    let networkId: String
    let token: CampaignEligibleToken?
}
