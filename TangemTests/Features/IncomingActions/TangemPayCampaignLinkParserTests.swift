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
/// The campaign key is read through `TangemPayCampaignService.campaignKey(fromDeepLinkValue:)`, which is gated
/// on the feature toggle — with it off every case here would pass for the wrong reason, so the suite is skipped
/// instead.
@Suite(
    "Tests for how a campaign link is read",
    .enabled(if: FeatureProvider.isAvailable(.tangemPayCustomCards))
)
struct TangemPayCampaignLinkParserTests {
    private let parser = TangemPayCampaignLinkParser()
    private let campaignKey = "tpay_for_harvard123"

    @Test("The campaign key is the whole deep_link_value, prefix included")
    func campaignLinkIsParsed() throws {
        let url = try #require(URL(string: "https://tangem.com/marketing?deep_link_value=\(campaignKey)"))

        let previousPendingKey = AppSettings.shared.pendingTangemPayCampaignKey
        defer { AppSettings.shared.pendingTangemPayCampaignKey = previousPendingKey }

        #expect(TangemPayCampaignLinkParser.matches(url))

        guard case .navigation(let deeplink) = parser.parse(url) else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .payCustomCard)
        #expect(deeplink.params.campaignId == campaignKey)
        #expect(deeplink.deeplinkString == url.absoluteString)
        #expect(AppSettings.shared.pendingTangemPayCampaignKey == campaignKey)
    }

    @Test("Another AppsFlyer deep link is not a campaign link")
    func unprefixedValueIsRejected() throws {
        let url = try #require(URL(string: "https://tangem.com/marketing?deep_link_value=tpay_mobileonboard"))

        #expect(TangemPayCampaignLinkParser.campaignKey(url) == nil)
        #expect(!TangemPayCampaignLinkParser.matches(url))
    }

    @Test("The bare prefix names no campaign")
    func barePrefixIsRejected() throws {
        let url = try #require(URL(string: "https://tangem.com/marketing?deep_link_value=tpay_for_"))

        #expect(TangemPayCampaignLinkParser.campaignKey(url) == nil)
        #expect(!TangemPayCampaignLinkParser.matches(url))
    }

    @Test("A link without deep_link_value is not a campaign link")
    func missingValueIsRejected() throws {
        let url = try #require(URL(string: "https://tangem.com/marketing"))

        #expect(TangemPayCampaignLinkParser.campaignKey(url) == nil)
        #expect(!TangemPayCampaignLinkParser.matches(url))
    }
}
