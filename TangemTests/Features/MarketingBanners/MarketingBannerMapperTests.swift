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
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, priority: 30),
                Fixtures.makeCampaign(id: 2, priority: 10),
                Fixtures.makeCampaign(id: 3, priority: 20),
            ]
        )

        #expect(banners.standalone.map(\.id) == [2, 3, 1])
    }

    @Test("Campaign without banner text is dropped")
    func dropsCampaignWithoutText() {
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, text: nil),
                Fixtures.makeCampaign(id: 2, text: "Visible"),
            ]
        )

        #expect(banners.standalone.map(\.id) == [2])
        #expect(banners.linked.isEmpty)
    }

    @Test("Banners are partitioned into standalone and linked")
    func partitionsStandaloneAndLinked() {
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, providerIds: ["mercuryo"], uiType: .linkedToProvider),
                Fixtures.makeCampaign(id: 2, uiType: .standalone),
            ]
        )

        #expect(banners.standalone.map(\.id) == [2])
        #expect(banners.linked.map(\.id) == [1])
    }

    @Test("Unknown uiType is dropped")
    func unknownUITypeIsDropped() {
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, uiType: .unknown("brand_new_type")),
                Fixtures.makeCampaign(id: 2, uiType: .standalone),
            ]
        )

        #expect(banners.standalone.map(\.id) == [2])
        #expect(banners.linked.isEmpty)
        #expect(banners.callToAction.isEmpty)
    }

    @Test("Call-to-action banners keep one priority-ordered list across both types")
    func callToActionBannersShareOnePriorityOrder() {
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, priority: 30, uiType: .pseudoProvider, buttonText: "Request"),
                Fixtures.makeCampaign(id: 2, priority: 10, uiType: .standaloneCTA, buttonText: "Join"),
                Fixtures.makeCampaign(id: 3, priority: 20, uiType: .pseudoProvider, buttonText: "Open"),
                Fixtures.makeCampaign(id: 4, priority: 5, uiType: .standalone),
            ]
        )

        #expect(banners.callToAction.map(\.id) == [2, 3, 1])
        #expect(banners.standalone.map(\.id) == [4])
        #expect(banners.linked.isEmpty)
    }

    @Test(
        "Call-to-action banner without button text is dropped",
        arguments: [MarketingCampaignsDTO.Banner.UIType.pseudoProvider, .standaloneCTA],
        [nil, ""]
    )
    func dropsCallToActionWithoutButtonText(uiType: MarketingCampaignsDTO.Banner.UIType, buttonText: String?) {
        let banner = MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(uiType: uiType, buttonText: buttonText)
        )

        #expect(banner == nil)
    }

    @Test(
        "Call-to-action banner without text is dropped",
        arguments: [MarketingCampaignsDTO.Banner.UIType.pseudoProvider, .standaloneCTA],
        [nil, ""]
    )
    func dropsCallToActionWithoutText(uiType: MarketingCampaignsDTO.Banner.UIType, text: String?) {
        let banner = MarketingBannerMapper.makeBanner(
            from: Fixtures.makeCampaign(uiType: uiType, text: text, buttonText: "Join")
        )

        #expect(banner == nil)
    }

    @Test("Pseudo-provider placement carries its labels, button and glow")
    func pseudoProviderPlacementCarriesFields() throws {
        let banner = try #require(MarketingBannerMapper.makeBanner(from: Fixtures.makeCampaign(
            uiType: .pseudoProvider,
            text: "Personal manager",
            deeplink: URL(string: "tangem://support"),
            categoryLabel: "Concierge for large purchases",
            subtitle: "Pay by bank transfer",
            etaLabel: "up to 4 hours",
            partnerLabel: "",
            buttonText: "Request",
            glow: true
        )))

        guard case .pseudoProvider(let content) = banner.placement else {
            Issue.record("Expected pseudoProvider placement")
            return
        }
        #expect(banner.text == "Personal manager")
        #expect(content.categoryLabel == "Concierge for large purchases")
        #expect(content.subtitle == "Pay by bank transfer")
        #expect(content.etaLabel == "up to 4 hours")
        #expect(content.partnerLabel == nil)
        #expect(content.buttonText == "Request")
        #expect(content.isGlowing)
        #expect(banner.isCallToAction)
        #expect(!banner.isStandalone)
        #expect(!banner.isLinkedToProvider)
    }

    @Test("Standalone CTA placement carries subtitle and button; missing glow means no glow")
    func standaloneCTAPlacementCarriesFields() throws {
        let banner = try #require(MarketingBannerMapper.makeBanner(from: Fixtures.makeCampaign(
            uiType: .standaloneCTA,
            subtitle: "Not available in your region yet",
            buttonText: "Join waitlist",
            glow: nil
        )))

        guard case .standaloneCTA(let content) = banner.placement else {
            Issue.record("Expected standaloneCTA placement")
            return
        }
        #expect(content.subtitle == "Not available in your region yet")
        #expect(content.buttonText == "Join waitlist")
        #expect(!content.isGlowing)
        #expect(banner.isCallToAction)
    }

    @Test("Campaigns outside their start/end window are filtered out")
    func filtersCampaignsOutsideDateWindow() {
        let now = Date(timeIntervalSince1970: 1_785_585_600)
        let past = now.addingTimeInterval(-100)
        let future = now.addingTimeInterval(100)

        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, startAt: future),
                Fixtures.makeCampaign(id: 2, endAt: past),
                Fixtures.makeCampaign(id: 3, startAt: past, endAt: future),
                Fixtures.makeCampaign(id: 4),
            ],
            now: now
        )

        #expect(banners.standalone.map(\.id) == [3, 4])
    }

    @Test("Campaign is visible at the exact startAt and endAt moments and with a one-sided window")
    func dateWindowBoundariesAreInclusive() {
        let now = Date(timeIntervalSince1970: 1_785_585_600)

        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1, startAt: now),
                Fixtures.makeCampaign(id: 2, endAt: now),
                Fixtures.makeCampaign(id: 3, startAt: now.addingTimeInterval(-100)),
                Fixtures.makeCampaign(id: 4, endAt: now.addingTimeInterval(100)),
            ],
            now: now
        )

        #expect(banners.standalone.map(\.id) == [1, 2, 3, 4])
    }

    @Test("removing(hiddenCampaignIds:) drops hidden banners by id, others stay")
    func removingDropsHiddenCampaigns() {
        let banners = MarketingBannerMapper.banners(
            from: [
                Fixtures.makeCampaign(id: 1),
                Fixtures.makeCampaign(id: 2),
                Fixtures.makeCampaign(id: 3, providerIds: ["mercuryo"], uiType: .linkedToProvider),
                Fixtures.makeCampaign(id: 4, uiType: .standaloneCTA, buttonText: "Join"),
                Fixtures.makeCampaign(id: 5, uiType: .pseudoProvider, buttonText: "Request"),
            ]
        )

        let visible = banners.removing(hiddenCampaignIds: [1, 3, 4])

        #expect(visible.standalone.map(\.id) == [2])
        #expect(visible.linked.isEmpty)
        #expect(visible.callToAction.map(\.id) == [5])
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
