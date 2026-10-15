//
//  CampaignEligibleToken.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CampaignEligibleToken: Hashable {
    let tokenId: String?
    let tokenAddress: String
    let tokenSymbol: String
    let tokenName: String
    let networkId: String
    let decimals: Int?
}
