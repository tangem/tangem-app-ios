//
//  LinkedMarketingBannerViewModelFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("LinkedMarketingBannerViewModelFactory", .tags(.marketingBanners))
final class LinkedMarketingBannerViewModelFactoryTests: LeakTrackingTestSuite {
    private func makeBanner(
        id: Int = 1,
        text: String = "Discover Bitcoin",
        providerIds: [String],
        deeplink: URL? = nil
    ) -> MarketingBanner {
        MarketingBanner(
            id: id,
            text: text,
            iconURL: nil,
            backgroundColorHex: nil,
            placement: .linkedToProvider(providerIds: providerIds),
            action: deeplink.map(MarketingBanner.Action.deeplink),
            isDismissible: false
        )
    }

    private func makeSpy() -> IncomingActionHandlerSpy {
        trackForMemoryLeaks(IncomingActionHandlerSpy())
    }

    @Test("Picks the first banner matching the provider id")
    func picksFirstMatchingBanner() throws {
        let banners = [
            makeBanner(id: 1, providerIds: ["moonpay"]),
            makeBanner(id: 2, text: "For Mercuryo", providerIds: ["mercuryo"]),
            makeBanner(id: 3, providerIds: ["mercuryo"]),
        ]

        let viewModel = try #require(LinkedMarketingBannerViewModelFactory.make(
            from: banners,
            providerId: "mercuryo",
            incomingActionHandler: makeSpy()
        ))

        #expect(viewModel.id == 2)
        #expect(viewModel.text == "For Mercuryo")
    }

    @Test("Returns nil when no banner matches the provider")
    func returnsNilWithoutMatch() {
        let viewModel = LinkedMarketingBannerViewModelFactory.make(
            from: [makeBanner(providerIds: ["moonpay"])],
            providerId: "mercuryo",
            incomingActionHandler: makeSpy()
        )

        #expect(viewModel == nil)
    }

    @Test("Standalone banners never match a provider")
    func standaloneBannersNeverMatch() {
        let standalone = MarketingBanner(
            id: 1,
            text: "Standalone",
            iconURL: nil,
            backgroundColorHex: nil,
            placement: .standalone,
            action: nil,
            isDismissible: true
        )

        let viewModel = LinkedMarketingBannerViewModelFactory.make(
            from: [standalone],
            providerId: "mercuryo",
            incomingActionHandler: makeSpy()
        )

        #expect(viewModel == nil)
    }

    @Test("Deeplink action forwards the URL to the incoming action handler")
    func deeplinkActionForwardsURL() throws {
        let deeplink = URL(string: "tangem://swap")!
        let spy = makeSpy()

        let viewModel = try #require(LinkedMarketingBannerViewModelFactory.make(
            from: [makeBanner(providerIds: ["mercuryo"], deeplink: deeplink)],
            providerId: "mercuryo",
            incomingActionHandler: spy
        ))

        let action = try #require(viewModel.action)
        action()

        #expect(spy.handledURLs == [deeplink])
    }

    @Test("Banner without deeplink produces a view model without action")
    func bannerWithoutDeeplinkHasNoAction() throws {
        let viewModel = try #require(LinkedMarketingBannerViewModelFactory.make(
            from: [makeBanner(providerIds: ["mercuryo"])],
            providerId: "mercuryo",
            incomingActionHandler: makeSpy()
        ))

        #expect(viewModel.action == nil)
    }
}
