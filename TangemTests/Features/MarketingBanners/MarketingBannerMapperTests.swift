//
//  MarketingBannerMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketingBannerMapper", .tags(.marketingBanners))
struct MarketingBannerMapperTests {
    private typealias Fixtures = MarketingCampaignsFixtures

    @Test("Campaigns are sorted by priority ascending")
    func sortsByPriorityAscending() {
        let banners = MarketingBannerMapper.banners(from: [
            Fixtures.makeCampaign(id: 1, priority: 30),
            Fixtures.makeCampaign(id: 2, priority: 10),
            Fixtures.makeCampaign(id: 3, priority: 20),
        ])

        #expect(banners.standalone.map(\.id) == [2, 3, 1])
    }

    @Test("Campaign without banner text is dropped")
    func dropsCampaignWithoutText() {
        let banners = MarketingBannerMapper.banners(from: [
            Fixtures.makeCampaign(id: 1, text: nil),
            Fixtures.makeCampaign(id: 2, text: "Visible"),
        ])

        #expect(banners.standalone.map(\.id) == [2])
        #expect(banners.linked.isEmpty)
    }

    @Test("Banners are partitioned into standalone and linked")
    func partitionsStandaloneAndLinked() {
        let banners = MarketingBannerMapper.banners(from: [
            Fixtures.makeCampaign(id: 1, providerIds: ["mercuryo"], uiType: .linkedToProvider),
            Fixtures.makeCampaign(id: 2, uiType: .standalone),
        ])

        #expect(banners.standalone.map(\.id) == [2])
        #expect(banners.linked.map(\.id) == [1])
    }

    @Test("Unknown uiType is treated as standalone")
    func unknownUITypeFallsBackToStandalone() {
        let banners = MarketingBannerMapper.banners(from: [
            Fixtures.makeCampaign(id: 1, uiType: .unknown("brand_new_type")),
        ])

        #expect(banners.standalone.map(\.id) == [1])
        #expect(banners.linked.isEmpty)
    }

    @Test("Linked placement carries providerIds; nil becomes an empty list")
    func linkedPlacementCarriesProviderIds() throws {
        let withProviders = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(providerIds: ["mercuryo", "simplex"], uiType: .linkedToProvider)
        ))
        let withoutProviders = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(providerIds: nil, uiType: .linkedToProvider)
        ))

        guard case .linkedToProvider(let providerIds) = withProviders.placement else {
            Issue.record("Expected linkedToProvider placement")
            return
        }
        #expect(providerIds == ["mercuryo", "simplex"])

        guard case .linkedToProvider(let emptyProviderIds) = withoutProviders.placement else {
            Issue.record("Expected linkedToProvider placement")
            return
        }
        #expect(emptyProviderIds.isEmpty)
    }

    @Test("Deeplink maps to an action, its absence means no action")
    func deeplinkMapsToAction() throws {
        let deeplink = URL(string: "tangem://swap")!

        let withDeeplink = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(deeplink: deeplink)
        ))
        let withoutDeeplink = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(deeplink: nil)
        ))

        guard case .deeplink(let url) = withDeeplink.action else {
            Issue.record("Expected deeplink action")
            return
        }
        #expect(url == deeplink)
        #expect(withoutDeeplink.action == nil)
    }

    @Test("Banner fields are mapped from the campaign", arguments: [true, false])
    func mapsBannerFields(dismissible: Bool) throws {
        let icon = URL(string: "https://cdn.tangem.com/dev/star.png")!

        let banner = try #require(MarketingBannerMapper.makeBanner(from: Fixtures.makeCampaign(
            id: 16,
            text: "Discover Bitcoin",
            icon: icon,
            bgColor: "#FF00FF",
            dismissible: dismissible
        )))

        #expect(banner.id == 16)
        #expect(banner.text == "Discover Bitcoin")
        #expect(banner.iconURL == icon)
        #expect(banner.backgroundColorHex == "#FF00FF")
        #expect(banner.isDismissible == dismissible)
    }

    @Test("matchesProvider matches only linked banners containing the id")
    func matchesProviderOnlyForLinkedBanners() throws {
        let linked = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(providerIds: ["mercuryo", "simplex"], uiType: .linkedToProvider)
        ))
        let standalone = try #require(MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(uiType: .standalone)
        ))

        #expect(linked.matchesProvider(id: "mercuryo"))
        #expect(linked.matchesProvider(id: "simplex"))
        #expect(!linked.matchesProvider(id: "moonpay"))
        #expect(!standalone.matchesProvider(id: "mercuryo"))

        #expect(!linked.isStandalone)
        #expect(standalone.isStandalone)
    }
}
