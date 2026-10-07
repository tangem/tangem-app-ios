//
//  PromoCampaignBannerMatcherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("PromoCampaignBannerMatcher")
struct PromoCampaignBannerMatcherTests {
    @Test("A banner without a campaign is shown, campaigns or not")
    func bannerWithoutCampaign() {
        #expect(PromoCampaignBannerMatcher.isVisible(campaignId: nil, campaigns: []))
        #expect(PromoCampaignBannerMatcher.isVisible(campaignId: nil, campaigns: [makeCampaign(id: 15)]))
    }

    @Test("A banner is shown when its campaign is eligible and not yet enrolled")
    func bannerWithEligibleCampaign() {
        #expect(PromoCampaignBannerMatcher.isVisible(campaignId: 15, campaigns: [makeCampaign(id: 15, isEnrolled: false)]))
    }

    @Test("A banner is hidden once the wallet has enrolled")
    func bannerWithEnrolledCampaign() {
        #expect(!PromoCampaignBannerMatcher.isVisible(campaignId: 15, campaigns: [makeCampaign(id: 15, isEnrolled: true)]))
    }

    @Test("A banner is hidden when its campaign did not come back for this wallet")
    func bannerWithoutMatchingCampaign() {
        #expect(!PromoCampaignBannerMatcher.isVisible(campaignId: 15, campaigns: []))
        #expect(!PromoCampaignBannerMatcher.isVisible(campaignId: 15, campaigns: [makeCampaign(id: 16)]))
    }

    @Test("An enrolled campaign hides its banner even when another campaign is eligible")
    func enrolledCampaignAmongOthers() {
        let campaigns = [
            makeCampaign(id: 16, isEnrolled: false),
            makeCampaign(id: 15, isEnrolled: true),
        ]

        #expect(!PromoCampaignBannerMatcher.isVisible(campaignId: 15, campaigns: campaigns))
    }
}

// MARK: - Fixtures

private extension PromoCampaignBannerMatcherTests {
    func makeCampaign(id: Int, isEnrolled: Bool = false) -> PromoCampaign {
        PromoCampaignFixtures.makeCampaign(id: id, isEnrolled: isEnrolled)
    }
}
