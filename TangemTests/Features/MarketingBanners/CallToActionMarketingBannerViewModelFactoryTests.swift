//
//  CallToActionMarketingBannerViewModelFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CallToActionMarketingBannerViewModelFactory", .tags(.marketingBanners))
struct CallToActionMarketingBannerViewModelFactoryTests {
    private func makeBanner(
        id: Int = 1,
        placement: MarketingBanner.Placement = .standaloneCTA(.init(subtitle: nil, buttonText: "Join", isGlowing: false)),
        deeplink: URL? = URL(string: "tangem://support"),
        iconURL: URL? = nil,
        isDismissible: Bool = false
    ) -> MarketingBanner {
        MarketingBanner(
            id: id,
            text: "Title",
            iconURL: iconURL,
            backgroundColorHex: nil,
            placement: placement,
            action: deeplink.map(MarketingBanner.Action.deeplink),
            isDismissible: isDismissible
        )
    }

    private func make(_ banner: MarketingBanner) -> CallToActionMarketingBanner? {
        CallToActionMarketingBannerViewModelFactory.make(from: banner)
    }

    @Test("A banner whose link the app or the browser can open is shown", arguments: [
        "https://partner.example.com/otc?ref=tangem",
        "tangem://support",
        "Tangem://support",
        "tangem://onramp?type=concierge_waitlist",
        "https://tangem.com/onramp",
        "https://tangem.com/some-page",
    ])
    func openableLinkIsKept(link: String) {
        #expect(make(makeBanner(deeplink: URL(string: link)!)) != nil)
    }

    @Test("A banner whose link neither the app nor the browser can open is dropped", arguments: [
        "http://partner.example.com/otc",
        "otherapp://open",
        "tangem://future_screen",
        "mailto:support@tangem.com",
        "tangem://onramp",
    ])
    func unopenableLinkIsDropped(link: String) {
        #expect(make(makeBanner(deeplink: URL(string: link)!)) == nil)
    }

    @Test("A banner without a link has nothing for its button to do and is dropped")
    func bannerWithoutLinkIsDropped() {
        #expect(make(makeBanner(deeplink: nil)) == nil)
    }

    @Test("Banners without a button are not call-to-action banners", arguments: [
        MarketingBanner.Placement.standalone,
        .linkedToProvider(providerIds: ["moonpay"]),
    ])
    func nonCallToActionPlacementsAreDropped(placement: MarketingBanner.Placement) {
        #expect(make(makeBanner(placement: placement)) == nil)
    }

    @Test("Pseudo-provider banner keeps its labels, button, glow and link")
    func pseudoProviderFieldsAreMapped() throws {
        let url = URL(string: "tangem://support")!
        let banner = try #require(make(makeBanner(
            id: 7,
            placement: .pseudoProvider(.init(
                categoryLabel: "Concierge for large purchases",
                subtitle: "Pay by bank transfer",
                etaLabel: "up to 4 hours",
                partnerLabel: "via MoonPay",
                buttonText: "Request",
                isGlowing: true
            )),
            deeplink: url
        )))

        guard case .pseudoProvider(let viewModel) = banner else {
            Issue.record("Expected a pseudo-provider banner, got \(banner)")
            return
        }

        #expect(viewModel.id == 7)
        #expect(viewModel.title == "Title")
        #expect(viewModel.buttonTitle == "Request")
        #expect(viewModel.isGlowing)
        #expect(viewModel.link == url)
        #expect(viewModel.content == .init(
            categoryLabel: "Concierge for large purchases",
            subtitle: "Pay by bank transfer",
            etaLabel: "up to 4 hours",
            partnerLabel: "via MoonPay"
        ))
    }

    @Test("Standalone banner keeps its subtitle, icon and button")
    func standaloneFieldsAreMapped() throws {
        let icon = URL(string: "https://cdn.tangem.com/percent.png")!
        let banner = try #require(make(makeBanner(
            placement: .standaloneCTA(.init(subtitle: "Not available in your region yet", buttonText: "Join waitlist", isGlowing: false)),
            iconURL: icon
        )))

        guard case .standalone(let viewModel) = banner else {
            Issue.record("Expected a standalone banner, got \(banner)")
            return
        }

        #expect(viewModel.buttonTitle == "Join waitlist")
        #expect(!viewModel.isGlowing)
        #expect(viewModel.content == .init(subtitle: "Not available in your region yet", iconURL: icon))
    }

    @Test("A changed link makes the banner differ, so the screen picks up the new button action")
    func changedLinkChangesBanner() {
        let old = make(makeBanner(deeplink: URL(string: "https://partner.example.com/a")!))
        let new = make(makeBanner(deeplink: URL(string: "https://partner.example.com/b")!))

        #expect(old != new)
    }

    @Test("A change in dismissibility makes the banner differ, so the close button follows it")
    func changedDismissibilityChangesBanner() {
        #expect(make(makeBanner(isDismissible: true)) != make(makeBanner(isDismissible: false)))
    }

    @Test("A banner keeps whether it can be closed", arguments: [true, false])
    func dismissibilityIsMapped(isDismissible: Bool) throws {
        guard case .standalone(let viewModel) = try #require(make(makeBanner(isDismissible: isDismissible))) else {
            Issue.record("Expected a standalone banner")
            return
        }

        #expect(viewModel.isDismissible == isDismissible)
    }
}
