//
//  CampaignEligibleTokenMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CampaignEligibleTokenMapper", .tags(.campaigns))
struct CampaignEligibleTokenMapperTests {
    private let sut = CampaignEligibleTokenMapper()

    @Test("A legacy promotion token maps every field")
    func legacyToken() {
        let token = PromotionCampaignsFixtures.makeToken()

        #expect(sut.map(token) == PromotionCampaignsFixtures.makeEligibleToken())
    }

    @Test("A legacy yield-boost token keeps its missing tokenId and decimals")
    func legacyTokenWithoutOptionalFields() {
        let token = PromotionCampaignsFixtures.makeToken(tokenId: nil, decimals: nil)

        #expect(sut.map(token) == PromotionCampaignsFixtures.makeEligibleToken(tokenId: nil, decimals: nil))
    }

    @Test("A promo campaign payout token maps every field")
    func payoutToken() {
        let token = PromoCampaignsDTO.PayoutToken(
            tokenAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
            networkId: "ethereum",
            tokenSymbol: "USDT",
            tokenName: "Tether USD",
            tokenId: "tether",
            decimals: 6
        )

        #expect(sut.map(token) == CampaignEligibleToken(
            tokenId: "tether",
            tokenAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
            tokenSymbol: "USDT",
            tokenName: "Tether USD",
            networkId: "ethereum",
            decimals: 6
        ))
    }

    @Test("Both contracts describing the same token map to an equal value")
    func contractsAgree() {
        let legacy = PromotionCampaignsFixtures.makeToken()
        let payout = PromoCampaignsDTO.PayoutToken(
            tokenAddress: legacy.tokenAddress,
            networkId: legacy.networkId,
            tokenSymbol: legacy.tokenSymbol,
            tokenName: legacy.tokenName,
            tokenId: legacy.tokenId,
            decimals: legacy.decimals
        )

        #expect(sut.map(legacy) == sut.map(payout))
    }
}
