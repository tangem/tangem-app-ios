//
//  CampaignEligibleTokenMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CampaignEligibleTokenMapper {
    func map(_ token: BannerPromotion.Response.Token) -> CampaignEligibleToken {
        CampaignEligibleToken(
            tokenId: token.tokenId,
            tokenAddress: token.tokenAddress,
            tokenSymbol: token.tokenSymbol,
            tokenName: token.tokenName,
            networkId: token.networkId,
            decimals: token.decimals
        )
    }

    func map(_ token: PromoCampaignsDTO.PayoutToken) -> CampaignEligibleToken {
        CampaignEligibleToken(
            tokenId: token.tokenId,
            tokenAddress: token.tokenAddress,
            tokenSymbol: token.tokenSymbol,
            tokenName: token.tokenName,
            networkId: token.networkId,
            decimals: token.decimals
        )
    }
}
