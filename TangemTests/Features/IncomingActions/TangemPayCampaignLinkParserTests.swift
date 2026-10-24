//
//  TangemPayCampaignLinkParserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Single source of truth for co-brand campaign link parsing.
@Suite("Tests for how a campaign link is read", .serialized)
struct TangemPayCampaignLinkParserTests {
    private let parser = TangemPayCampaignLinkParser()
    private let campaignKey = "tpay_for_harvard123"

    @Test(
        "The campaign key is the whole deep_link_value, prefix included",
        arguments: [
            "https://tangem.com/marketing",
            "https://join.tangem.com/abcd",
        ]
    )
    func campaignLinkIsParsed(link: String) throws {
        let url = try #require(URL(string: "\(link)?deep_link_value=\(campaignKey)"))

        #expect(TangemPayCampaignLinkParser.matches(url))
        #expect(parser.parse(url) == .navigation(.payCustomCard(PayCustomCardDeeplink(campaignKey: campaignKey))))
    }

    @Test("On internal and debug builds the app's own scheme names the campaign too")
    func appSchemeCampaignLinkIsParsedOnInternalBuilds() throws {
        let url = try #require(URL(string: "tangem://marketing?deep_link_value=\(campaignKey)"))

        #expect(TangemPayCampaignLinkParser.matches(url))
        #expect(parser.parse(url) == .navigation(.payCustomCard(PayCustomCardDeeplink(campaignKey: campaignKey))))
    }

    @Test(
        "The same value from an untrusted source names no campaign",
        arguments: [
            "https://evil.example.com/marketing?deep_link_value=tpay_for_harvard123",
            "tangem://not-marketing?deep_link_value=tpay_for_harvard123",
        ]
    )
    func foreignLinksAreRejected(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(TangemPayCampaignLinkParser.campaignKey(url) == nil)
        #expect(parser.parse(url) == nil)
    }

    @Test(
        "A link that names no campaign is not a campaign link",
        arguments: [
            // Another AppsFlyer deep link: onboarding, which has a parser of its own.
            "https://tangem.com/marketing?deep_link_value=tpay_mobileonboard",
            // The bare prefix names no campaign.
            "https://tangem.com/marketing?deep_link_value=tpay_for_",
            "https://tangem.com/marketing",
            // The key is carried on to the backend and back into a link, so it is held to the shape every
            // identifier a link of ours carries has.
            "https://tangem.com/marketing?deep_link_value=tpay_for_harvard%20123",
            "https://tangem.com/marketing?deep_link_value=tpay_for_../harvard",
        ]
    )
    func otherLinksAreRejected(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(TangemPayCampaignLinkParser.campaignKey(url) == nil)
        #expect(!TangemPayCampaignLinkParser.matches(url))
        #expect(parser.parse(url) == nil)
    }
}
