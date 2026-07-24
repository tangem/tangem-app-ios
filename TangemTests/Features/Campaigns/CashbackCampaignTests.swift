//
//  CashbackCampaignTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CashbackCampaign", .tags(.campaigns))
struct CashbackCampaignTests {
    @Test("Campaign ids match the backend contract")
    func campaignIdsMatchBackendContract() {
        #expect(CashbackCampaign(rawValue: "whale-swap-cashback") == .whaleSwap)
        #expect(CashbackCampaign(rawValue: "reactivation-cashback") == .reactivation)
        #expect(CashbackCampaign(rawValue: "unknown-campaign") == nil)
        #expect(CashbackCampaign(rawValue: "") == nil)
    }

    @Test("Terms documents point to the per-campaign PDFs")
    func termsURLsPointToPerCampaignPDFs() {
        #expect(CashbackCampaign.whaleSwap.termsURL?.absoluteString == "https://tangem.com/docs/en/whale-swap-cashback-terms.pdf")
        #expect(CashbackCampaign.reactivation.termsURL?.absoluteString == "https://tangem.com/docs/en/summer-swap-cashback-terms.pdf")
    }

    @Test("Learn-more links lead to the per-campaign blog posts")
    func blogPostsLeadToPerCampaignArticles() {
        let builder = TangemBlogUrlBuilder()

        #expect(builder.url(post: CashbackCampaign.whaleSwap.blogPost).path == "/embed/blog/post/whale-swap")
        #expect(builder.url(post: CashbackCampaign.reactivation.blogPost).path == "/embed/blog/post/summer-swap")
    }

    @Test("Promo images are served from the stories folder with per-campaign file names")
    func promoImageURLsUseStoriesFolder() {
        #expect(CashbackCampaign.whaleSwap.promoImageURL.absoluteString.hasSuffix("/stories/Whale_Swap_Cashback.webp"))
        #expect(CashbackCampaign.reactivation.promoImageURL.absoluteString.hasSuffix("/stories/Reactivation_Cashback.webp"))
    }
}
